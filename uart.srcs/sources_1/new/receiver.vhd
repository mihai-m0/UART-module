library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity receiver is
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
end receiver;

architecture Behavioral of receiver is
    type states is (idle,start_bit,data_bits,stop_bit,cleanup);
    signal state:states:= idle;
    signal read_bit,temp_read_bit:std_logic;
    signal ticks:integer range 0 to tick_limit-1 :=0;
    signal index:integer range 0 to 7 :=0;
    signal is_valid:std_logic:='0';
    signal result:std_logic_vector(7 downto 0):=x"00";
begin
    sample_data:process(clk) begin
        if rising_edge(clk) then 
            temp_read_bit<= din;
            read_bit<= temp_read_bit;
        end if;
    end process;
    
    update_states:process(clk) begin
        if rising_edge(clk) then
            case state is 
                when idle => 
                    ticks<=0;
                    index<=0;
                    is_valid<='0';
                    
                    if read_bit='0' then 
                        state<=start_bit;
                    end if;
                
                when start_bit =>
                    if ticks < (tick_limit-1)/2 then
                        ticks<=ticks+1;
                    else
                        if read_bit='0' then --we can start reading data
                            ticks<=0;
                            state<=data_bits;
                        else 
                            state<=idle;
                            ticks<=0;
                        end if;
                    end if;
                    
               when data_bits=>
                    if ticks<tick_limit-1 then 
                        ticks<=ticks+1;
                    else
                        ticks<=0;
                        result(index)<=read_bit;
                        if index=7 then
                            index<=0;
                            state<=stop_bit;
                        else
                            index<=index+1; 
                        end if;
                    end if;
                
                when stop_bit=>
                    if ticks<tick_limit-1 then
                        ticks<=ticks+1;
                    else
                        is_valid<='1';
                        state<=cleanup;
                        ticks<=0;
                    end if;
                
               when cleanup =>
                    is_valid<='0';
                    if ticks<(tick_limit-1)/2 then
                        ticks<=ticks+1;
                    else
                        state<=idle;
                    end if;
               when others=> state<=idle; 
            end case;
        end if;
        end process;
    valid<=is_valid;
    dout<=result;
end Behavioral;
