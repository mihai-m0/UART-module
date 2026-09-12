library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity transmitter is
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
end transmitter;

architecture Behavioral of transmitter is
    type states is (idle,start_bit,data_bits,stop_bit,cleanup);
    signal state:states:= idle;
    signal ticks:integer:=0;
    signal index:integer:=0;
    signal result:std_logic:='1';
    
    signal input:std_logic_vector(7 downto 0):=x"00";
    
begin
    dout<=result;
    process(clk) begin
        if rising_edge(clk) then
            case state is
                when idle=>
                    working<='0';
                    result<='1';
                    done<='0';
                    ticks<=0;
                    index<=0;
                    
                    if data_request='1' then
                        state<=start_bit;
                        input<=din;
                    end if;
                    
                 when start_bit =>
                    result<='0';
                    working<='1';
                    if ticks=tick_limit-1 then 
                        state<=data_bits;
                        ticks<=0;
                    else
                        ticks<=ticks+1;   
                    end if;
                 when data_bits =>
                    result<=input(index);
                    if ticks=tick_limit-1 then
                        ticks<=0;
                        if index=7 then
                            index<=0;
                            state<=stop_bit;
                        else
                            index<=index+1;
                        end if;
                    else 
                        ticks<=ticks+1;
                    end if;      
                    
                 when stop_bit=>
                    result<='1';
                    if ticks=tick_limit-1 then
                        ticks<=0;
                        state<=cleanup;
                    else
                        ticks<=ticks+1;
                 end if;
                 
                 when cleanup=>
                    result<='1';
                    done<='1';
                    working<='0';
                    state<=idle;
                 when others=> state<=idle;         
                    
            end case;
        end if;
        
    end process;

end Behavioral;
