library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;


entity uart_tb is
end uart_tb;

architecture Behavioral of uart_tb is
    component transmitter is
    generic(
        tick_limit:integer:=999--how many clocks need to pass in order to read another bit?
                               -- answer: clk_frq/baud_rate
    );
    
    port(
        clk:in std_logic;
        data_request:in std_logic;
        din:in std_logic_vector(7 downto 0);
        
        dout:out std_logic;
        working:out std_logic;
        done:out std_logic
    );
    end component;
    
    component receiver is
    generic(
        tick_limit:integer:=999--how many clocks need to pass in order to read another bit?
                               -- answer: clk_frq/baud_rate
    );
    
    port(
        clk:in std_logic;
        din:in std_logic;
        valid:out std_logic;
        dout:out std_logic_vector(7 downto 0)
    );
    end component;

    signal main_clk:std_logic:='0';
    signal clk_period:time:=100 ns;

    constant tick_limit:integer:=87;
    
    signal tr_line:std_logic:='1';
    signal receiver_out:std_logic_vector(7 downto 0):=x"00";
    signal transmitter_in:std_logic_vector(7 downto 0):=x"00";
    
    signal request_data:std_logic:='0';
    signal transmitter_done:std_logic:='0';
    signal data_valid:std_logic:='0';
   
    type test_bytes is array(6 downto 0) of std_logic_vector(7 downto 0);
    signal arr : test_bytes:=(x"00",x"FF", x"AB", x"55", x"AA", x"01", x"80");
    signal pass,fail:integer:=0;


   
begin
    tx: transmitter
        generic map(tick_limit)
        port map(main_clk,request_data,transmitter_in,tr_line,open,transmitter_done);
    rx: receiver
        generic map(tick_limit)
        port map(main_clk,tr_line,data_valid,receiver_out);

    generate_clk:process
    begin
        main_clk<='0';
        wait for clk_period/2;
        main_clk<='1';
        wait for clk_period/2;
    end process;
    
    simulate:process
         procedure send_n_count(in_byte:in std_logic_vector(7 downto 0)) is
        begin
            wait until rising_edge(main_clk);
            request_data<='1';
            transmitter_in<=in_byte;
            wait until rising_edge(main_clk);
            request_data<='0';
            wait until transmitter_done='1';
            
            if receiver_out=in_byte then
                pass<=pass+1;
            else 
                fail<=fail+1;
            end if;
            
           
            wait for clk_period;
        end procedure;
    begin
        wait until rising_edge(main_clk);
        wait until rising_edge(main_clk);
        
        for bt in arr'range loop
            send_n_count(arr(bt));
        end loop;
        
        report "test summary:" & integer'image(pass) & " have passed and " & integer'image(fail) &" have failed"
        severity note;
        
        
        wait;
    end process;
    
    process
    begin
        wait for 1000 us;
        report "TIMEOUT: Simulation did not complete in time" severity failure;
    end process;
            
            

end Behavioral;
