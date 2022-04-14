`timescale 1ns/1ps

interface i2c_if       #(
	int I2C_ADDR_WIDTH = 7,
	int I2C_DATA_WIDTH = 8,
	int NUM_I2C_BUSSES = 16
)
(

	// System signals
	input wire clk_i,
	input wire rst_i,
	// Master signals
	input triand [NUM_I2C_BUSSES-1:0] scl_i,
	input triand [NUM_I2C_BUSSES-1:0] sda_i,
	output wire [NUM_I2C_BUSSES-1:0] sda_o, 
	output wire [NUM_I2C_BUSSES-1:0] scl_o 
);
	// Types and Enum Switches for Interrupts
	import i2c_types_pkg::*;
	import printing_pkg::*;
	enum bit [1:0] {INTR_CLEAR=2'b00,RAISE_START=2'b01, RAISE_STOP=2'b10, RAISE_RESTART=2'b11} intrs;
	enum bit {STOP, START} stst;
	enum bit {ACK, NACK} aknk;
	enum bit {MONITOR_AND_DRIVER, MONITOR_ONLY} mntr;

	// Configured address of this Slave
	bit [8:0] slave_address;

	// Internal Signals: Control and Start/Stop/Restart Interrupts
	bit transfer_in_progress;
	bit sampler_running;
	bit [1:0] driver_interrupt;

	// Internal Driver Signals and Buffers
	bit [8:0] driver_buffer;
	bit slv_write_response;
	bit [7:0] slave_receive_buffer[$];
	bit [7:0] slave_transmit_buffer[$];
	bit address_mismatch;

	// Internal Monitor Signals and Buffers
	bit enable_driver;
	bit [1:0] monitor_interrupt;
	bit [8:0] monitor_buffer;

	// Indices of MSB and LSB of a Byte in a larger buffer
	parameter int MSB=8;
	parameter int LSB=1;

	// Registers and logic to select I2C Wires from Multiline Bus
	int bus_selector;

	// Register for driving Serial Data Line by Slave BFM
	logic [NUM_I2C_BUSSES-1:0] sda_drive=16'bz;
	assign sda_o = sda_drive;

	logic [NUM_I2C_BUSSES-1:0] scl_drive=16'bz;
	assign scl_o = scl_drive;

	longint clk_count;
	bit not_first_measure;

	always @(posedge clk_i) ++clk_count;
	always @(negedge scl_i[bus_selector]) begin 
		clk_count = 0;
		@(posedge scl_i[bus_selector]) rst_clock();
	end
	// Clockstretching and arb parameters
	int stretch_qty=0;
	int read_stretch_qty=0;

	parameter int AVG_LEN=3;
	longint measured_clock[AVG_LEN];

	bit enable_cs=1;
	int arbitration_wait_cycles=1000000;
	bit cause_arbitration_loss;
	function void reset_counters(); 
	foreach(measured_clock[i])measured_clock[i]=0;
	not_first_measure = 1'b1;
	endfunction
	//_____________________________________________________________________________________\\
	//                      RESET, CONFIGURE, and BYPASS TASKS                             \\
	//_____________________________________________________________________________________\\
	// ****************************************************************************
	// Reset the internal  clock counter and maintain sma
	// ****************************************************************************
	function void rst_clock();
	int i;
	longint sum;
	sum = 0;
	if(!not_first_measure) begin 
		if(clk_count == 0) return;
		for(i=0; i<AVG_LEN;++i) measured_clock[i] = clk_count;
		not_first_measure=1'b1;
	end
	for(i=AVG_LEN; i>0;--i) measured_clock[i] = measured_clock[i-1];
	measured_clock[0] = clk_count;
	clk_count = 0;
	for(i=0; i<AVG_LEN;++i) sum += measured_clock[i];
	measured_clock[0] = sum/AVG_LEN;
	endfunction


	// ****************************************************************************
	// Reset the Slave BFM and configure it to hold input_addr address.
	// Reset task automatically starts the sampler for detecting start/stop
	// ****************************************************************************
	task reset_and_configure(input bit [8:0] input_addr, input int sel_bus);
	
		bus_selector = NUM_I2C_BUSSES-sel_bus-1;
		slave_address = (input_addr << 2);
		transfer_in_progress = STOP;
		sampler_running = STOP;
		enable_driver = MONITOR_ONLY; // Assume that we only need monitor until driver is called
		driver_interrupt = INTR_CLEAR;
		monitor_interrupt = INTR_CLEAR;
		connection_negotiation_sampler();
	endtask

	task reset();
		
		bus_selector = 0;
		slave_address = 0;
		transfer_in_progress = STOP;
		sampler_running = STOP;
		enable_driver = MONITOR_ONLY; // Assume that we only need monitor until driver is called
		driver_interrupt = INTR_CLEAR;
		monitor_interrupt = INTR_CLEAR;
		connection_negotiation_sampler();
	endtask

	task configure(input bit [8:0] input_addr, input int sel_bus);
		bus_selector = NUM_I2C_BUSSES-sel_bus-1;
		slave_address = (input_addr << 2);
	endtask

	// ****************************************************************************
	// Empty the Driver's buffers on a reset
	// ****************************************************************************
	task reset_test_buffers();
		slave_receive_buffer.delete();
		slave_transmit_buffer.delete();
	endtask

	// ****************************************************************************
	// Provide data to be transmitted by the slave BFM upon a requested read op from the Master
	// 		BYPASS TASK: Bypasses DUT and BFM implementation to deposit read data directly
	// 					into driver's memory, which is then sent back via I2C and DUT.
	// ****************************************************************************
	task provide_read_data(input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
		foreach(read_data[i]) slave_transmit_buffer.push_back(read_data[i]);
		wait(slave_transmit_buffer.size == 0);
		transfer_complete = 1'b1;
	endtask

	//_____________________________________________________________________________________\\
	//                       SAMPLER: Start/Stop Conditions                                \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Continuously sample sda_i[bus_selector] at 100MHz monitoring for Start and Stop signals.
	// Since these signals occur in "Normally Illegal" areas, eg, while clk_i
	// is held high, a sampler is used to raise an interrupt to the rest of the slave BFM. 
	// The sampler is able to detect conditions at any time, including while the BFM driver
	// and monitor are busy with other tasks.
	// ****************************************************************************
	task connection_negotiation_sampler();
		static bit [1:0] control;
		static logic [3:0] samples;
		sampler_running = START;
		@(posedge clk_i); // Wait for Serial clock to rise to 
		forever begin
			// Continuously sample sda and scl at 100MHz
			samples[0]=sda_i[bus_selector];
			samples[1]=scl_i[bus_selector];
			#10 samples[2]=sda_i[bus_selector];
			samples[3]=scl_i[bus_selector];

			// If we find a valid transition indicating start/stop/restart, Store values in control
			if(samples[1]==1'b1 && samples[3]==1'b1) begin
				control[0] = samples[0];
				control[1] = samples[2];
			end

			// Check control and raise relevant interrupt code to rest of system if conditions met
			case(control)
				2'b01: begin // start or Re-start
					if(transfer_in_progress== STOP) begin // Not Running, Start Detected
						driver_interrupt = RAISE_START;
						monitor_interrupt = RAISE_START;
					end
					else begin // Already running, Restart detected
						driver_interrupt = RAISE_RESTART;
						monitor_interrupt = RAISE_RESTART;
					end
					transfer_in_progress = START;end
				2'b10: begin // Stop Condition Detected
					driver_interrupt = RAISE_STOP;
					monitor_interrupt = RAISE_STOP;
					transfer_in_progress = STOP;
				end
			endcase
		end
	endtask

	//_____________________________________________________________________________________\\
	//                       CLOCKSTRETCHING IMPLEMENTATION TASKS                          \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// During a ADRESS WRITE or DATA WRITE, the clock may be stretched between each bit,  
	// Slowing the bus speed. Force clock level low for stretch_qty system clock cycles
	// stretch_qty must be set by system driver.
	// ****************************************************************************
	task clockstretch();
	if(!enable_cs) return;
		#15 scl_drive[bus_selector] = 1'b0;
		repeat(stretch_qty) @(posedge clk_i);
		scl_drive[bus_selector] = 1'bz;
	endtask

	// ****************************************************************************
	// During a DATA READ, the clock may be stretched before the first bit, and
	// between each subsequent bit until the final bit is written. Clockstretching
	// must end at this final bit, allowing the master to retake control of the 
	// system to transmit it's ACK or NACK. Clock shall be stretched between bits by
	// read_stretch_qty system cycles; read_stretch_qty must be set by system driver.
	// ****************************************************************************
	task clockstretch_read();
	if(!enable_cs) return;
		#15 scl_drive[bus_selector] = 1'b0;
		repeat(read_stretch_qty) @(posedge clk_i);
		scl_drive[bus_selector] = 1'bz;
	endtask

	//_____________________________________________________________________________________\\
	//                       ARBITRATION OVERRIDE TASKS 		                           \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// Excplicitly cause a system state where arbitration shall be lost by the master. 
	// Release this state after arbitration_wait_cycles system cycles
	// ****************************************************************************
	task force_arbitration_loss();
			@(scl_i) sda_drive = 16'h00;
			repeat(997) @(posedge clk_i);
			sda_drive = 16'hzz;
	endtask

	//_____________________________________________________________________________________\\
	//                       I2C DRIVER IMPLEMENTATION TASKS                               \\
	//_____________________________________________________________________________________\\

	// ****************************************************************************
	// TOP of callstack for the slave BFM. Waits for DUT to initiate a transfer 
	// (as signaled by the sampler) and proceeds to transfer control to the 
	// next step of the internal request handler (address detection).
	// ****************************************************************************
	task wait_for_i2c_transfer(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
		enable_driver <= MONITOR_AND_DRIVER; // Tell The monitor/sampler that there is also a driver in parallel
		wait(transfer_in_progress == START &&
		(driver_interrupt == RAISE_START || driver_interrupt == RAISE_RESTART)
		);
		driver_interrupt = INTR_CLEAR; // Reset the interrupt on detected

		driver_receive_address(op, write_data); // Handle the request
	endtask

	// ****************************************************************************
	// Read both the transmitted address, and the requested operation code, from the 
	// I2C Bus. If, and only if, the received address matches the BFM configured 
	// address *OR* the protocol-defined ALL-CALL address, respond with  an ACK.
	// Otherwise, DUT will drive NACK high and interpret that no address match was 
	// found  on the I2C BUS.
	// On match, Interpret operation code, and branch control to the correct handler
	// for READS or WRITES, and pass data buffer through in case of WRITES.
	// ****************************************************************************
	task driver_receive_address(output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
		static bit [7:0] write_buf[$];
		
		address_mismatch = 1'b0;

		// Read Address and opcode from serial bus
		for(int i=MSB;i>=LSB;i--) begin
			@(posedge scl_i[bus_selector]) if(cause_arbitration_loss) force_arbitration_loss();
			driver_buffer[i] = sda_i[bus_selector];
			@(negedge scl_i[bus_selector])begin
				clockstretch();
				 if(intr_raised()) return;
			end
		end

		// Determine whether address matches configured slave address OR the All-Call address
		if(driver_buffer[MSB:2]==slave_address[MSB:2] || driver_buffer[MSB:2]==7'b000_0000) begin
			// SEND THE ACK Back to master upon a match
			//driver_transmit_ACK();
			sda_drive[bus_selector] = 1'b0;
			@(posedge scl_i[bus_selector]);
		
			@(negedge scl_i[bus_selector]) sda_drive[bus_selector] =1'bz;
			// Determine the operation code
			op = driver_buffer[1]? I2_READ : I2_WRITE;

			// Branch to handle requested operation
			if(op==I2_WRITE) driver_receive_write_data(write_buf);
			else driver_transmit_read_data();
		end else begin
			address_mismatch = 1'b1;
			@(posedge scl_i[bus_selector]); // Allow nack to pass to the master
			@(negedge scl_i[bus_selector]);
						op = driver_buffer[1]? I2_READ : I2_WRITE;

			// Branch to handle requested operation
			if(op==I2_WRITE) driver_receive_write_data(write_buf);
			else driver_transmit_read_data();
		end
		
		// Copy queued captured write data into return array.
		write_data = write_buf;
	endtask

	// ****************************************************************************
	// Handle a series of one or more bytes of data for WRITE operation request. 
	// Continuously accept data until connection is terminated, sending an ACK 
	// after each complete byte. Branch to invidual-byte and ack-sending tasks.
	// ****************************************************************************
	task driver_receive_write_data(output bit [I2C_DATA_WIDTH-1:0] write_data [$]);
		forever begin
			// Read a byte from the data bus
			driver_read_single_byte();
			if(intr_raised()) return;
			// Check to ensure we have not encountered a stop/restart condition, if so, 
			// return control to caller for next transfer to begin
			if(!intr_raised() && !address_mismatch) driver_transmit_ACK();
			else if(!intr_raised() && address_mismatch) driver_transmit_NACK();
			else return;

			// Reply with the ACK of this byte


			// Store byte in Driver's local buffer and returnable buffer
			slave_receive_buffer.push_back(driver_buffer[MSB:LSB]);
			write_data.push_back(driver_buffer[MSB:LSB]);

		end
	endtask

	// ****************************************************************************
	// Handle a single byte being received on the I2C Bus. 
	//  	NB: ACK/NACK is handled elsewhere, here, we simply read 8 bits into the 
	//			system buffer and return.
	// ****************************************************************************
	task driver_read_single_byte();
		for(int i=MSB;i>=LSB;i--) begin
			// Capture the value
			while(scl_i[bus_selector] == 1'b0 && !intr_raised()) #1 if(intr_raised()) return;
			driver_buffer[i] = sda_i[bus_selector];
			//@(posedge scl_i[bus_selector]) driver_buffer[i] = sda_i[bus_selector];
			// Sample/Watch for a possible restart/stop signal until negedge scl_i[bus_selector]
			while(scl_i[bus_selector] ==1'b1)	#1	if(intr_raised()) return;
			clockstretch();
		end
	endtask

	// ****************************************************************************
	// Take control  of the I2C Data bus for one scl cycle, sending  an explicit ACK
	// back to the master during this cycle. Release control and return.
	// ****************************************************************************
	task driver_transmit_ACK();
		sda_drive[bus_selector] = 1'b0;
		@(posedge scl_i[bus_selector]);
		
		@(negedge scl_i[bus_selector]) sda_drive[bus_selector] =1'bz;
		clockstretch();
	endtask


	// ****************************************************************************
	// Take control  of the I2C Data bus for one scl cycle, sending  an explicit NACK
	// back to the master during this cycle. Release control and return.
	// ****************************************************************************
	task driver_transmit_NACK();
		sda_drive[bus_selector] = 1'b1;
		@(posedge scl_i[bus_selector]);
		
		@(negedge scl_i[bus_selector]) sda_drive[bus_selector] =1'bz;
		clockstretch();
	endtask


	// ****************************************************************************
	// Handle responding to a read request with a series of one or more bytes
	// of read data, by branching to lower-level encapsulations for individual bytes.
	// Based on ACK/NACK Status from the MASTER, return once transfer is complete.
	// 		DEPENDENCY: provide_read_data() must be called (by main TB) prior to response 
	//					with read data.
	// ****************************************************************************
	task driver_transmit_read_data();
		static bit local_ack;
		local_ack = 0;
		while(slave_transmit_buffer.size > 0) begin
			// Get data out of transmit buffer to send
			driver_buffer[MSB:LSB] = slave_transmit_buffer.pop_front();

			//Send a byte on sda while clock is high			
			driver_transmit_single_byte();

			// Check for ack/NACK from master
			sda_drive[bus_selector] <= 1'bz;
			@(posedge scl_i[bus_selector]) local_ack = sda_i[bus_selector];

			// Check for NACK/DONE or STOP/RESTART CONDTION
			if(local_ack==NACK) return;
			
			@(negedge scl_i[bus_selector]) if(intr_raised()) return;
		end
	endtask

	// ****************************************************************************
	// Take control of serial data bus, and send a single byte from the system byte 
	// buffer.
	//		DEPENDENCY: System byte buffer must be populated with fresh data prior
	//					to executing this task.
	// ****************************************************************************
	task driver_transmit_single_byte();
		for(int i=MSB;i>=LSB;i--) begin
			sda_drive[bus_selector] <= driver_buffer[i];
			clockstretch_read();
			@(posedge scl_i[bus_selector]);
			@(negedge scl_i[bus_selector]); 
		end
	endtask

	//_____________________________________________________________________________________\\
	//                       I2C MONITOR IMPLEMENTATION TASKS                               \\
	//_____________________________________________________________________________________\\	

	// ****************************************************************************
	// Top-level monitoring of I2C Transfers. Utilizes similar logic to the driver tasks,
	// but will monitor for data being driven both by the DUT, the local driver, or external
	// blocks. Utilizes interrupts and buffers that are fully decoupled from driver operation
	// such that the monitor can be run on systems with externally driven signal.
	// Detects start, captures any address and opcode, and branches to data handler, monitor_record_data()
	// ****************************************************************************
	task monitor(output bit[I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op,
		output bit [I2C_DATA_WIDTH-1:0] data [], output int sel_bus, output bit nack);

		static bit ack;
		static bit [7:0] monitor_data[$];
		monitor_data.delete;
		reset_counters();
		wait(transfer_in_progress == START && (monitor_interrupt == RAISE_START || monitor_interrupt == RAISE_RESTART));
		monitor_interrupt = INTR_CLEAR; // Reset the interrupt on detected

		sel_bus = bus_selector;

		// Capture the incoming address, operation, and ack
		for(int i=MSB;i>=0;i--) begin
			@(posedge scl_i[bus_selector]);
			monitor_buffer[i] = sda_i[bus_selector];
		end
		addr = monitor_buffer[MSB:2];
		op = monitor_buffer[1]? I2_READ : I2_WRITE;
		ack = monitor_buffer[0];

		// Record the transferred data
		monitor_record_data(monitor_data, op, nack);

		// Copy transferred data to output array
		data=monitor_data;
	endtask

	// ****************************************************************************
	// Continuously record bytes of data until a transaction is completed. 
	// ****************************************************************************
	task monitor_record_data(output bit [I2C_DATA_WIDTH-1:0] monitor_data [$], input i2c_op_t op, output bit nack);
		static bit [8:0] rec_dat_mon_buf;
		int i;
		monitor_data.delete; // Clear static buffer of data from prior calls
		@(negedge scl_i[bus_selector]);

		forever begin
			for(i=MSB;i>=0;i--) begin
				if(mon_intr_raised()) break;
				wait(scl_i[bus_selector] == 1'b1 ||monitor_interrupt == RAISE_STOP||monitor_interrupt == RAISE_START||monitor_interrupt == RAISE_RESTART);
				if(mon_intr_raised()) break;
				rec_dat_mon_buf[i] = sda_i[bus_selector];
				wait(scl_i[bus_selector] == 1'b0 || monitor_interrupt == RAISE_STOP||monitor_interrupt == RAISE_START||monitor_interrupt == RAISE_RESTART);
				if(monitor_interrupt == RAISE_STOP) break;
			end
			nack = rec_dat_mon_buf[0];
			if(i == 0 || i == -1)	monitor_data.push_back(rec_dat_mon_buf[MSB:LSB]);
			if(mon_intr_raised()) return;
			if(op==I2_READ && rec_dat_mon_buf[0]==NACK) return; // Return on Read op and NACK (End Call)

		end
	endtask

	//_____________________________________________________________________________________\\
	//                                  INTERRUPT MANAGEMENT                               \\
	//_____________________________________________________________________________________\\

	// Check if ANY driver-layer interrupt has been raised
	function bit intr_raised();
		intr_raised = (driver_interrupt == RAISE_STOP ||
		driver_interrupt == RAISE_RESTART ||
		driver_interrupt == RAISE_START
		);
	endfunction

	// Check if ANY monitor-layer interrupt has been raised
	function bit mon_intr_raised();
		mon_intr_raised = (monitor_interrupt == RAISE_STOP ||
		monitor_interrupt == RAISE_RESTART ||
		monitor_interrupt == RAISE_START
		);
	endfunction

	//_____________________________________________________________________________________\\
	//                                  REPORTING FUNCTIONALITY                            \\
	//_____________________________________________________________________________________\\		

	// Getter for debug: Retrieve an entry from the driver's received-data buffer
	function byte get_receive_entry(int i);
		return slave_receive_buffer[i];
	endfunction

endinterface
