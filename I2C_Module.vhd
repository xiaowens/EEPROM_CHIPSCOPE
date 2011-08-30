----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:47:52 07/27/2011 
-- Design Name: 
-- Module Name:    I2C_Module - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--========================================================================
entity I2C_Module is
	generic (
		constant BIT_WIDTH : integer := 8		--DEFAULT: ONE BYTE
			);
	port (
		CLK		: IN		STD_LOGIC;
		
		SCL		: INOUT	STD_LOGIC;
		SDA		: INOUT	STD_LOGIC;
		
		-----------COMMAND DEFINE------------------
		--'000'--CHECK_COMMAND
		--'001'--WRITE_BYTE
		--'010'--READ_BYTE
		--'011'--START
		--'100'--SEND_NO_ACK
		--'101'--WAIT_FOR_ACK
		--'110'--SEND_ACK
		--'111'--STOP
		
		COMMAND		: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);		
		-----------------------------------------------
		--after EXECUTE the COMMAND
		--set it back to '0' after send the signal '1'.
		EXECUTE		: IN	STD_LOGIC;		 
		-----------------------------------------------
		--showing which COMMAND (or state) is running
		COMMAND_RUNNING			: OUT	STD_LOGIC_vector(2 downto 0);
		-----------------------------------------------
		--data to be written to slave 
		DATA_IN_BYTE		: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
		--data was read out from slave
		DATA_OUT_BYTE		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0)		
			);
end I2C_Module;

--=========================================================================
architecture Behavioral of I2C_Module is
	--------------------------SIGNAL---------------------------------
	type I2C_STATE_TYPE is 
		(	
			st_check_state,
			st_start,			
			st_write_byte,	
			st_read_byte,
			--st_idle,
			st_send_no_ack,		
			st_wait_for_ack,
			st_send_ack,		
			st_stop				
		);

	signal state      		: I2C_STATE_TYPE := st_check_state;
	------------------------------------------------------------------
begin
	
	PROCESS (CLK) 
	--=============================================================================
		------------COMMANDS FOR I2C MODULE USED HERE--------------------
		CONSTANT CMD_CHECK_COMMAND			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";		
		CONSTANT CMD_WRITE_BYTE				: STD_LOGIC_VECTOR(2 DOWNTO 0) := "001"; 
		CONSTANT CMD_READ_BYTE				: STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
		CONSTANT CMD_START					: STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
		CONSTANT CMD_SEND_NO_ACK			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
		CONSTANT CMD_WAIT_FOR_ACK			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";
		CONSTANT CMD_SEND_ACK				: STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
		CONSTANT CMD_STOP						: STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
		----------------------------------------------------------------
	--=============================================================================
		-------------------------------------------------------------------------------
		variable data_to_write_byte			: std_logic_vector(7 downto 0) := x"00";
		variable data_to_read_byte				: std_logic_vector(7 downto 0) := x"00";
		variable step_counter					: unsigned(1 downto 0) 	:= "00";
		variable bit_counter						: integer range 0 to BIT_WIDTH  := 0;
		--number of cycles will wait for the 'ACK' from slave
		variable wait_counter					: integer range 0 to 255 := 0;
		-------------------------------------------------------------------------------
	BEGIN		
		IF RISING_EDGE(CLK) THEN
			---------------------START CASE STATE--------------------------------
			CASE state IS
			-------------------------------------------------------------
			WHEN st_check_state =>
				COMMAND_RUNNING <= "000";
				if (EXECUTE = '1') then
					wait_counter := 0;
					step_counter := "00";
					bit_counter := 0;
					-------------START CASE COMMAND-----------
					CASE COMMAND IS
					WHEN CMD_CHECK_COMMAND =>
						state <= st_check_state;		
					WHEN CMD_WRITE_BYTE =>
						state <= st_write_byte;
					WHEN CMD_READ_BYTE =>
						state <= st_read_byte;
					WHEN CMD_START =>
						state <= st_start;		
					WHEN CMD_SEND_NO_ACK =>
						state <= st_send_no_ack;
					WHEN CMD_WAIT_FOR_ACK =>
						state <= st_wait_for_ack;
					WHEN CMD_SEND_ACK =>
						state <= st_send_ack;
					WHEN CMD_STOP =>
						state <= st_stop;
					WHEN OTHERS =>
						state <= st_check_state;
					END CASE;
					-------------END CASE COMMAND-----------
--				--doesn't work!!
--				else --If there are multiple masters, release the bus when not using it.(not sure if it works)
--					if (wait_counter >= 20) then
--						if (step_counter = 0) then
--							SCL <= '0';
--							step_counter := step_counter + 1;
--						elsif (step_counter = 1) then
--							--SDA <= '0';
--							SDA <= 'Z';
--							--step_counter := step_counter + 1;
--						else
--						end if;
--					else
--						wait_counter := wait_counter + 1;
--					end if;
					
				end if;	
			-------------------------------------------------------------	
			WHEN st_start =>
				COMMAND_RUNNING <= CMD_START;
				if (step_counter = 0) then		
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif (step_counter = 1) then
					SDA <= '1';
					step_counter := step_counter + 1;
				elsif (step_counter = 2) then
					SCL <= '1';
					step_counter := step_counter + 1;
				else
					SDA <= '0';
					if EXECUTE = '0' then
						step_counter := "00";
						state <= st_check_state;
					end if;
				end if;	
			-------------------------------------------------------------			
			WHEN st_write_byte =>
				COMMAND_RUNNING <= CMD_WRITE_BYTE;
				data_to_write_byte := DATA_IN_BYTE;
				if bit_counter < BIT_WIDTH then   
					if step_counter = 0 then 
						SCL <= '0';
						step_counter := step_counter + 1;
					elsif step_counter = 1 then
								SDA <= data_to_write_byte(7 - bit_counter);
								step_counter := step_counter + 1;
					elsif step_counter = 2 then
								SCL <= '1';
								bit_counter := bit_counter + 1;
								step_counter := "00";
					end if;
				else   --after 1 byte is sent
					if EXECUTE = '0' then
						bit_counter := 0;
						state <= st_check_state;
					end if;		
				end if;
						
			-------------------------------------------------------------			
			WHEN st_read_byte =>
				COMMAND_RUNNING <= CMD_READ_BYTE;
				if bit_counter < BIT_WIDTH  then   
					if step_counter = 0 then 
						SCL <= '0';
						step_counter := step_counter + 1;
					elsif step_counter = 1 then
						SCL <= '1';
						step_counter := step_counter + 1;
					elsif step_counter = 2 then
						data_to_read_byte(7 - bit_counter) := SDA;  
						bit_counter := bit_counter + 1;
						step_counter := "00";
					end if;
				else   --after 1 byte is read
					if step_counter = 0 then
						DATA_OUT_BYTE <= data_to_read_byte;
						step_counter := step_counter + 1;
					else
						if EXECUTE = '0' then
							step_counter := "00";
							state <= st_check_state;
							bit_counter := 0;
						end if;	
					end if;		
				end if;
						
			-------------------------------------------------------------			
			--WHEN st_idle =>
			--	COMMAND_RUNNING <= CMD_CHECK_STATE;
			--	SCL <= '1';
			--	SDA <= '1';
			--	if EXECUTE = '0' then
			--		state <= st_check_state;
			--	end if;
			-------------------------------------------------------------			
			WHEN st_send_no_ack =>
				COMMAND_RUNNING <= CMD_SEND_NO_ACK;
				if (step_counter = 0) then
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif (step_counter = 1) then
					SDA <= '1';  			 --sending the 'NO' ack to the slave
					step_counter := step_counter + 1;
				elsif (step_counter = 2) then
					SCL <= '1';
					step_counter := step_counter + 1;
				elsif (step_counter = 3) then
					SCL <= '0';
					if EXECUTE = '0' then
						step_counter := "00";
						state <= st_check_state;
					end if;
				end if;
						
			-------------------------------------------------------------		
			WHEN st_wait_for_ack =>
				COMMAND_RUNNING <= CMD_WAIT_FOR_ACK;
				if step_counter = 0 then
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif step_counter = 1 then
					SDA <= 'Z';
					step_counter := step_counter + 1;
				elsif step_counter = 2 then
					SCL <= '1';
					step_counter := step_counter + 1;
				elsif step_counter = 3 then
					if SDA = '0' then
						if EXECUTE = '0' then
							step_counter := "00";
							state <= st_check_state;
						end if;
					else
						wait_counter := wait_counter + 1;
						if wait_counter > 200 then		--wait 200 cycles if not receiving 'ack' from slave
							if EXECUTE = '0' then
								step_counter := "00";
								wait_counter := 0;
								state <= st_check_state;
							end if;
						end if;
					end if;
				end if;
						
			-------------------------------------------------------------			
			WHEN st_send_ack =>
				COMMAND_RUNNING <= CMD_SEND_ACK;
				if (step_counter = 0) then
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif (step_counter = 1) then
					SDA <= '0';  			 --sending the ack to the slave
					step_counter := step_counter + 1;
				elsif (step_counter = 2) then
					SCL <= '1';
					step_counter := step_counter + 1;
				elsif (step_counter = 3) then
					SCL <= '0';
					SDA <= 'Z';				 --release the SDA wire for the slave
					if EXECUTE = '0' then
						step_counter := "00";
						state <= st_check_state;
					end if;	
				end if;
			-------------------------------------------------------------		
			WHEN st_stop =>
				COMMAND_RUNNING <= CMD_STOP;
				if step_counter = 0 then
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif step_counter = 1 then
					SDA <= '0';
					step_counter := step_counter + 1;
				elsif step_counter = 2 then
					SCL <= '1';
					step_counter := step_counter + 1;
				else
					SDA <= '1';
					if EXECUTE = '0' then
						step_counter := "00";
						state <= st_check_state;
					end if;
				end if;
				
			END CASE;		
			---------------------END CASE STATE--------------------------------
		END IF;  --RISING_EDGE(CLK)
	END PROCESS;

end Behavioral;

