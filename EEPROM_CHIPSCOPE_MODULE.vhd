----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:35:00 08/27/2011 
-- Design Name: 
-- Module Name:    EEPROM_CHIPSCOPE_MODULE - Behavioral 
-- Project Name: 	
-- Target Devices: Spartan-3A/3AN; 
-- Tool versions: 
-- Description: 	Using Chipscope to write and read 16 bytes to EEPROM at any given address.
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

entity EEPROM_CHIPSCOPE_MODULE is

	generic(
		STRING_SIZE			: integer := 16	--# of bytes write and read at one time from chipscope.
		);
		
	port(
		bclk_50MHz			: IN		STD_LOGIC;
		SCL			: INOUT	STD_LOGIC;
		SDA			: INOUT	STD_LOGIC;
		
		VCC_PIN		: OUT		STD_LOGIC;		--PROVIDE POWER FOR THE EEPROM
		WP_PIN		: OUT		STD_LOGIC;		--WHEN IT'S '1', WRITE PROTECT IS ENABLED. READ ONLY
														--WHEN IT'S '0', WRITE OPERATION IS ENABLED
														
		mon			: out		std_logic_vector(2 downto 0)	--for debugging
		);
		
end EEPROM_CHIPSCOPE_MODULE;

architecture Behavioral of EEPROM_CHIPSCOPE_MODULE is
--=========================================================================================
	----------------------------------------------------------------------------------------
	COMPONENT EEPROM_I2C_INTERFACE is
		generic(
		CONSTANT PAGE_SIZE			: integer := 32
		);
	port(
		CLK			: IN	STD_LOGIC;
		ADDRESS		: IN	STD_LOGIC_VECTOR(12 DOWNTO 0);
		
		COMMAND							: IN		STD_LOGIC_VECTOR(2 DOWNTO 0);
	
		----------------------------------------------
		--total # of bytes to read from EEPROM
		--it will be the index of bytes when transfer out the data 
		NUM_OF_BYTES		: IN	STD_LOGIC_VECTOR(5 DOWNTO 0);	
		----------------------------------------------
		EXECUTE				: IN	STD_LOGIC;
		
		COMMAND_RUNNING	: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
		
		INDEX_OF_BYTES		: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);	--showing which byte is transferred out. MAX # OF BYTES => 2^5=32 BYTES
		DATA_OUT_BYTE		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		DATA_IN_BYTE					: IN		STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		SCL					: INOUT STD_LOGIC;
		SDA					: INOUT STD_LOGIC

			);
	end COMPONENT;
	
	--------------------CHIPSCOPE-----------------------------------------
	component ICON
		PORT (
			CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
			);

	end component;
	component VIO
		PORT (
			CONTROL 	: INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
			CLK 		: IN STD_LOGIC;
			SYNC_IN 	: IN STD_LOGIC_VECTOR(255 DOWNTO 0);
			SYNC_OUT : OUT STD_LOGIC_VECTOR(255 DOWNTO 0)
			);

	end component;
	----------------------------------------------------------------------------

--===============================SIGNAL BEGIN=================================================================
	SIGNAL COMMAND_EEPROM					: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL ADDRESS_EEPROM					: STD_LOGIC_VECTOR(12 DOWNTO 0);
	SIGNAL NUM_OF_BYTES_EEPROM				: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL COMMAND_RUNNING_EEPROM			: STD_LOGIC_vector(2 downto 0);
	SIGNAL INDEX_OF_BYTES_EEPROM			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL EXECUTE_EEPROM					: STD_LOGIC := '0'; 
	SIGNAL SCL_EEPROM							: STD_LOGIC;
	SIGNAL SDA_EEPROM							: STD_LOGIC;
	signal DATA_OUT_BYTE_EEPROM			: std_logic_vector(7 downto 0);
	signal DATA_IN_BYTE_EEPROM				: STD_LOGIC_VECTOR(7 DOWNTO 0);

	---------------------------------------------------------------------------
	SIGNAL CLK_COUNTER					: UNSIGNED(9 DOWNTO 0) := x"00"&"00";
	
	SIGNAL SCL_INTERNAL	: STD_LOGIC;
	SIGNAL SDA_INTERNAL	: STD_LOGIC;
		
	SIGNAL INTERNAL_CHIPSCOPE_CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	SIGNAL INTERNAL_CHIPSCOPE_VIO_IN : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL INTERNAL_CHIPSCOPE_VIO_OUT : STD_LOGIC_VECTOR(255 DOWNTO 0);
--===============================SIGNAL END=================================================================	

begin
--=================================================================================
	--****************Power and Write Protection**************
	VCC_PIN <= '1';
	--WP_PIN <= '1';		--WRITE PRECTED ENABLED. READ ONLY. 
	
	WP_PIN <= '0';
	--********************************************************
	---------------------------------------------------------	
	eeprom		: EEPROM_I2C_INTERFACE
	port map (
		CLK			=> CLK_COUNTER(9),
		ADDRESS		=> ADDRESS_EEPROM,
		COMMAND		=> COMMAND_EEPROM,
		NUM_OF_BYTES		=>	NUM_OF_BYTES_EEPROM,
		
		EXECUTE				=> EXECUTE_EEPROM,
		
		COMMAND_RUNNING	=> COMMAND_RUNNING_EEPROM,
		INDEX_OF_BYTES		=> INDEX_OF_BYTES_EEPROM,
		DATA_OUT_BYTE		=> DATA_OUT_BYTE_EEPROM,
		DATA_IN_BYTE		=> DATA_IN_BYTE_EEPROM,
		
		SCL	=> SCL_EEPROM,
		SDA	=> SDA_EEPROM

		);
		

	---------------------------------------------------------
	CHIPSCOPE_ICON : ICON
	PORT MAP (
		CONTROL0 => INTERNAL_CHIPSCOPE_CONTROL
	 );


	CHIPSCOPE_VIO : VIO
	PORT MAP(
		CONTROL => INTERNAL_CHIPSCOPE_CONTROL,
		CLK => CLK_COUNTER(6),
		SYNC_IN => INTERNAL_CHIPSCOPE_VIO_IN,
		SYNC_OUT => INTERNAL_CHIPSCOPE_VIO_OUT
	 );
	
		
	--=========================================================================
	reduce_requency: PROCESS(bclk_50MHz)
	BEGIN
		IF RISING_EDGE(bclk_50MHz) THEN
			
			CLK_COUNTER <= CLK_COUNTER + 1;
			
		end if;
	END PROCESS reduce_requency;
	--=========================================================================

	process (CLK_COUNTER(9))
		--======================================================================
		-----------COMMAND FOR EEPROM_I2C_INTERFACE MODULE----------------
		CONSTANT CMD_CHECK_COMMAND			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
		CONSTANT CMD_SET_ADDRESS			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";	--only for 'Read' part
		CONSTANT CMD_READ_EEPROM			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
		CONSTANT CMD_TRANSFER_READ_OUT	: STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
		
		CONSTANT CMD_SAVE_DATA_BYTE				: STD_LOGIC_VECTOR(2 DOWNTO 0) := "001"; 
		CONSTANT CMD_WRITE_TO_EEPROM_BYTES		: STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
		--CONSTANT CMD_RESET_EEPROM_ADDRESS		: STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";	--no need
		CONSTANT CMD_RESET_BYTES_SAVED			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
	-----------------------------------------------------------------
	type DATA_BYTES_TYPE is array(0 TO STRING_SIZE - 1) of std_logic_vector(7 downto 0);
	
	variable bytes_to_write					: DATA_BYTES_TYPE := (OTHERS => x"20"); --default: "space"

	variable bytes_to_write_counter				: integer range 0 to STRING_SIZE := 0;
	
	variable bytes_after_read						: DATA_BYTES_TYPE;
	variable bytes_after_read_counter, i		: integer range 0 to STRING_SIZE := 0;
	
	variable counter, step_counter				:	integer range 0 to 15 := 0;
	variable  sub_step_counter						: integer range 0 to 7 := 0;
--	variable is_data_correct 						: std_logic := '1';
--	variable wait_counter							: integer range 0 to 127 := 0;
		--======================================================================
	BEGIN
		IF RISING_EDGE(CLK_COUNTER(9)) THEN
			
			
			--#############################

			IF EXECUTE_EEPROM = '1' THEN
				EXECUTE_EEPROM <= '0';			--RESET SIGNAL 'EXECUTE' TO '0'!
			END IF;
			--#############################
--			for i in 0 to STRING_SIZE-1 loop
--					bytes_to_write(i) := internal_CHIPSCOPE_VIO_OUT(7+8*i downto 0+8*i);
--			end loop;
--			
--			for i in 0 to STRING_SIZE-1 loop
--					INTERNAL_CHIPSCOPE_VIO_IN(7+8*i downto 0+8*i) <= bytes_to_write(i);
--			end loop;
			
			if INTERNAL_CHIPSCOPE_VIO_OUT(141) = '1' and 
						INTERNAL_CHIPSCOPE_VIO_OUT(142) /= '1' then	--'Read' signal from Chipscope
				if step_counter = 0 then
					if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
						ADDRESS_EEPROM <= INTERNAL_CHIPSCOPE_VIO_OUT(140 downto 128);
						COMMAND_EEPROM <= CMD_SET_ADDRESS;
						EXECUTE_EEPROM <= '1';
						step_counter := step_counter + 1;
					end if; 
				elsif step_counter = 1 then
					if COMMAND_RUNNING_EEPROM = CMD_SET_ADDRESS then
						step_counter := step_counter + 1;
					end if;
				elsif step_counter = 2 then
					if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
						NUM_OF_BYTES_EEPROM <= std_logic_vector(to_unsigned(STRING_SIZE, 6));		--READ 'STRING_SIZE' BYTES
						COMMAND_EEPROM <= CMD_READ_EEPROM;
						EXECUTE_EEPROM <= '1';
						step_counter := step_counter + 1;
					end if; 
				elsif step_counter = 3 then
					if COMMAND_RUNNING_EEPROM = CMD_READ_EEPROM then
						step_counter := step_counter + 1;
					end if;
				
				elsif step_counter = 4 then
					if bytes_after_read_counter < STRING_SIZE then
						if sub_step_counter = 0  then
							if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
								NUM_OF_BYTES_EEPROM <= std_logic_vector(to_unsigned(bytes_after_read_counter, 6));
								COMMAND_EEPROM <= CMD_TRANSFER_READ_OUT;
								EXECUTE_EEPROM <= '1';
								sub_step_counter := sub_step_counter + 1;
							end if;
						elsif sub_step_counter = 1 then
							if COMMAND_RUNNING_EEPROM = CMD_TRANSFER_READ_OUT then
								sub_step_counter := sub_step_counter + 1;
							end if;
						
						else
							if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
								bytes_after_read(bytes_after_read_counter) := DATA_OUT_BYTE_EEPROM;
								bytes_after_read_counter := bytes_after_read_counter + 1;
								sub_step_counter := 0;
							end if;
						end if;
					else --after all bytes are transfered out
						bytes_after_read_counter := 0;
						step_counter := step_counter + 1;
					end if;
				else	--show the read-out on Chipscope
					for i in 0 to STRING_SIZE-1 loop
						INTERNAL_CHIPSCOPE_VIO_IN(7+8*i downto 0+8*i) <= bytes_after_read(i);
					end loop;
					
										
					internal_CHIPSCOPE_VIO_IN(128) <= '1';
				end if;
			
				
			------------------------Write Part---------------------------------------------------------		
			elsif INTERNAL_CHIPSCOPE_VIO_OUT(141) /= '1' and 
						INTERNAL_CHIPSCOPE_VIO_OUT(142) = '1' then	--when 'Write' signal from Chipscope is 'on'
					
				
--				for i in 0 to STRING_SIZE-1 loop
--					bytes_to_write(i) := internal_CHIPSCOPE_VIO_OUT(7+8*i downto 0+8*i);
--				end loop;
				
					
				if counter = 0 then
					
					
					if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
						COMMAND_EEPROM <= CMD_RESET_BYTES_SAVED;	--clear bytes saved
						EXECUTE_EEPROM <= '1';
						counter := counter + 1;
					end if;
				elsif counter = 1 then
					if COMMAND_RUNNING_EEPROM = CMD_RESET_BYTES_SAVED then	
						counter := counter + 1;
					end if;

				elsif counter = 2 then	--transfer all the data in the array.
					if bytes_to_write_counter < STRING_SIZE then
						if step_counter = 0 then
							if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then	
								DATA_IN_BYTE_EEPROM <= bytes_to_write(bytes_to_write_counter);
								COMMAND_EEPROM <= CMD_SAVE_DATA_BYTE;	--SAVE THE BYTE
								EXECUTE_EEPROM <= '1';
								step_counter := step_counter + 1;
							end if;
						elsif step_counter = 1 then
							if COMMAND_RUNNING_EEPROM = CMD_SAVE_DATA_BYTE then
								bytes_to_write_counter := bytes_to_write_counter + 1;
								step_counter := 0;
							end if;
						end if;
					else	--all bytes are sent to EEPROM_I2C_INTERFACE module
						bytes_to_write_counter := 0;
						counter := counter + 1;
					end if;

				elsif counter = 3 then
					if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then
						ADDRESS_EEPROM <= INTERNAL_CHIPSCOPE_VIO_OUT(140 downto 128);
						COMMAND_EEPROM <= CMD_SET_ADDRESS;
						EXECUTE_EEPROM <= '1';
						counter := counter + 1;
					end if; 
				elsif counter = 4 then
					if COMMAND_RUNNING_EEPROM = CMD_SET_ADDRESS then
						for i in 0 to STRING_SIZE-1 loop
								bytes_to_write(i) := internal_CHIPSCOPE_VIO_OUT(7+8*i downto 0+8*i);
						end loop;
						
						for i in 0 to STRING_SIZE-1 loop
								INTERNAL_CHIPSCOPE_VIO_IN(7+8*i downto 0+8*i) <= bytes_to_write(i);
						end loop;
						counter := counter + 1;
					end if;
				
				elsif counter = 5 then
					if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then		
						--ADDRESS_EEPROM <= INTERNAL_CHIPSCOPE_VIO_OUT(140 downto 128);
						COMMAND_EEPROM <= CMD_WRITE_TO_EEPROM_BYTES;	--WRITE DATA TO EEPROM
						EXECUTE_EEPROM <= '1';
						counter := counter + 1;
					end if;
				elsif counter = 6 then
					
					if COMMAND_RUNNING_EEPROM = CMD_WRITE_TO_EEPROM_BYTES then		
						counter := counter + 1;
					end if;
				else 
					if COMMAND_RUNNING_EEPROM = CMD_CHECK_COMMAND then	
						internal_CHIPSCOPE_VIO_IN(128) <= '1';
					end if;
				end if;
			else --clear all the counters, and ready for the next operation.			
				counter := 0;
				step_counter := 0;
				sub_step_counter := 0;
				internal_CHIPSCOPE_VIO_IN(128) <= '0';

			end if;
			

		END IF;
		
			
		
	END PROCESS;

	mon(0) <= CLK_COUNTER(9);
	mon(1) <= SCL_EEPROM;
	mon(2) <= SDA_EEPROM;
	
	

	SCL <= SCL_EEPROM;
	SDA <= SDA_EEPROM;

--=================================================================================
end Behavioral;

