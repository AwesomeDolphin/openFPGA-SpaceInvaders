module invaders_system (

	// Inputs
	input               clk,
	input					  clk_74a,
	input					  clk_audio,
	input               rst_n,
	input					  display_enable,
	input	[7:0]				ram_read_data /* synthesis keep */,
	input	[9:0]				y_count /* synthesis keep */,


	input   wire    [31:0]  bridge_addr,
	input   wire            bridge_wr,
	input   wire    [31:0]  bridge_wr_data,
	input	  wire				bridge_endian_little,

	input	  wire    [31:0]  control_pad /* synthesis keep */,
	
	input	  wire    [31:0]  dip_switches,

	output  reg           ram1_word_rd,
	output  reg				 ram1_word_wr,
	output  reg   [23:0]  ram1_word_addr,
	output  reg   [31:0]  ram1_word_data,
	input      [31:0]  ram1_word_q,
	input              ram1_word_busy,
	
	output	[15:0]			audio_data,				

	input 					menu_visible,

	// Outputs
	output 		[12:0]	ram_address /* synthesis keep */,
	output 		[7:0]		ram_write_data /* synthesis keep */,
	output  		ram_write_en /* synthesis keep */
);

localparam STATE_NEXT				= 5'd1;

reg [3:0]	cpu_clock_counter /* synthesis keep */;
reg			cpu_clock_enable /* synthesis keep */;

wire pause = pause_key | menu_visible_s;
reg pause_key;
reg left_trig_p;

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		pause_key <= 1'b0;
		left_trig_p <= 1'b0;
	end else begin
		left_trig_p <= control_pad_s[8];
		if ((left_trig_p != control_pad_s[8]) && control_pad_s[8] == 1'b1) begin
			pause_key <= ~pause_key;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cpu_clock_counter <= 4'd0;
		cpu_clock_enable <= 1'b0;
	end else begin
		if (cpu_clock_counter == 4'd9) begin
			cpu_clock_counter <= 4'd0;
			cpu_clock_enable <= ~pause;
		end else begin
			cpu_clock_counter <= cpu_clock_counter + 1;
			cpu_clock_enable <= 1'b0;
		end
	end
end

reg irq_n;
reg [7:0] irq_rst;
reg [9:0] y_count1;

always @(posedge clk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		irq_n <= 1'b1;
	end else begin
		if (cpu_irq_cycle_n == 1'b0) begin
			irq_n <= 1'b1;
		end else begin
			y_count1 <= y_count;
			if (y_count != y_count1) begin
				if (y_count == 10'd96) begin
					irq_rst <= 8'hcf;
					irq_n <= 1'b0;
				end else if (y_count == 10'd224) begin
					irq_rst <= 8'hd7;
					irq_n <= 1'b0;
				end 
			end
		end
	end
end

wire [15:0]	cpu_address /* synthesis keep */;
reg [7:0]	cpu_data_in /* synthesis keep */;
wire [7:0]	cpu_data_out /* synthesis keep */;
wire [7:0]	rom_read_data /* synthesis keep */;
wire			cpu_read_cycle_n /* synthesis keep */;
wire			cpu_write_cycle_n /* synthesis keep */;
wire			cpu_memory_cycle_n /* synthesis keep */;
wire			cpu_io_cycle_n /* synthesis keep */;
wire 			cpu_processor_cycle_1 /* synthesis keep */;
reg			cpu_irq_cycle_n /* synthesis keep */;

reg [15:0]	barrel_shifter;
reg [2:0]   barrel_shift_amount;

assign ram_address = cpu_address;
assign ram_write_en = (cpu_address[13] == 1'b1) && (cpu_memory_cycle_n == 1'b0) && (cpu_write_cycle_n == 1'b0);
assign ram_write_data = cpu_data_out;

wire    [31:0]  control_pad_s /* synthesis keep */;
synch_3 #(.WIDTH(32)) scontrol(control_pad, control_pad_s, clk);
wire    [31:0]  dip_switches_s /* synthesis keep */;
synch_3 #(.WIDTH(32)) sswitches(dip_switches, dip_switches_s, clk);
wire		menu_visible_s;
synch_3	smenu(menu_visible, menu_visible_s, clk);

always @(*) begin
	cpu_data_in = 0;
	if (cpu_irq_cycle_n == 1'b0) begin
		cpu_data_in <= irq_rst;
	end else if (cpu_read_cycle_n == 1'b0) begin
		if (cpu_memory_cycle_n == 1'b0) begin
			if (cpu_address[13] == 1'b0) begin
				cpu_data_in = rom_read_data;
			end else begin
				cpu_data_in = ram_read_data;
			end
		end else if (~cpu_io_cycle_n && cpu_irq_cycle_n) begin
			if (cpu_read_cycle_n == 1'b0) begin
				case (cpu_address[1:0])
					2'b00: cpu_data_in = {1'b0, control_pad_s[3], control_pad_s[2], control_pad_s[4], 4'b1111};
					2'b01: cpu_data_in = {1'b0, control_pad_s[3], control_pad_s[2], control_pad_s[4], 1'b1, control_pad_s[15], control_pad_s[14], control_pad_s[9]};
					2'b10: cpu_data_in = dip_switches_s[7:0] | {1'b0, control_pad_s[3], control_pad_s[2], control_pad_s[4], 4'b0000};
					2'b11: cpu_data_in = barrel_shifter >> (8 - barrel_shift_amount);
					default: cpu_data_in = 8'b00000000;
				endcase
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		barrel_shifter = 16'h0000;
	end else begin
		if (cpu_clock_enable == 1'b1) begin
			if (~cpu_io_cycle_n && cpu_irq_cycle_n) begin
				if (cpu_write_cycle_n == 1'b0) begin
					case (cpu_address[2:0]) 
						3'b010: begin
							barrel_shift_amount <= cpu_data_out;
						end
						3'b011: begin
							ufo_visible <= cpu_data_out[0];
							player_shot <= cpu_data_out[1];
							player_hit  <= cpu_data_out[2];
							invader_hit <= cpu_data_out[3];
							extended_play <= cpu_data_out[4];
						end
						3'b100: begin
							barrel_shifter[7:0] <= barrel_shifter[15:8];
							barrel_shifter[15:8] <= cpu_data_out;
						end
						3'b101: begin
							march1 <= cpu_data_out[0];
							march2 <= cpu_data_out[1];
							march3 <= cpu_data_out[2];
							march4 <= cpu_data_out[3];
							ufo_hit  <= cpu_data_out[4];
						end
					endcase
				end
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		cpu_irq_cycle_n <= 1'b1;
	end else begin
		if ((cpu_processor_cycle_1 == 1'b0) && (cpu_io_cycle_n == 1'b0)) begin
			cpu_irq_cycle_n <= 1'b0;
		end else begin
			cpu_irq_cycle_n <= 1'b1;
		end
	end
end

wire [12:0] loadram_addr;
wire [7:0] loadram_data;
wire loadram_enable;

data_loader #(
    .ADDRESS_SIZE(12),
    .WRITE_MEM_CLOCK_DELAY(4)
) rom_loader (
    .clk_74a(clk_74a),
    .clk_memory(clk_74a),

    .bridge_wr(bridge_wr),
    .bridge_endian_little(bridge_endian_little),
    .bridge_addr(bridge_addr),
    .bridge_wr_data(bridge_wr_data),

    .write_en(loadram_enable),
    .write_addr(loadram_addr),
    .write_data(loadram_data)
);

mf_systemrom mp3 (
    .clock_a         ( clk_74a ),
	 .clock_b			( clk ),
    
	 .address_a			( loadram_addr ),
	 .data_a				( loadram_data ),
	 .wren_a				( loadram_enable),
	 
	 .address_b			( cpu_address ),
	 .q_b					( rom_read_data ),
	 .wren_b				( 1'b0 )
);

tv80n #(.Mode(2)) intel8080 (
    .clk				( clk ),
	 .cen				( cpu_clock_enable),
	 .reset_n		( rst_n ),
	 
	 .A				( cpu_address ),
	 .di				( cpu_data_in ),
	 .dout			( cpu_data_out ),
	 .rd_n			( cpu_read_cycle_n ),
	 .wr_n			( cpu_write_cycle_n ),
	 .mreq_n			( cpu_memory_cycle_n ),
	 .iorq_n			( cpu_io_cycle_n ),
	 .m1_n			( cpu_processor_cycle_1 ),
	 .int_n			( irq_n ),
	 .busrq_n		( 1'b1 ),
	 .nmi_n			( 1'b1 ),
	 .wait_n			( 1'b1 ),
);
    
	wire           soundram_word_rd;
	wire				soundram_word_wr;
	wire   [23:0]  soundram_word_addr;
	wire   [31:0]  soundram_word_data;
	reg						ufo_visible;
	reg				player_shot;
	reg						player_hit;
	reg						invader_hit;
	reg				march1;
	reg				march2;
	reg				march3;
	reg				march4;
	reg						ufo_hit;
	reg						extended_play;

	always ram1_word_rd = soundram_word_rd;
	always ram1_word_wr = soundram_word_wr;
	always ram1_word_addr = soundram_word_addr;
	always ram1_word_data = soundram_word_data;
	
invaders_sound sound_system (
	 .clk_audio		   ( clk_audio),
    .rst_n          	( rst_n ),
	 .display_enable  ( display_enable ),
	 
	 .ram1_word_rd		( soundram_word_rd ),
	 .ram1_word_wr    ( soundram_word_wr ),
	 .ram1_word_addr  ( soundram_word_addr ),
	 .ram1_word_data  ( soundram_word_data ),
	 .ram1_word_q     ( ram1_word_q ),
	 .ram1_word_busy  ( ram1_word_busy ),
	 
	 .ufo_visible		( ufo_visible ),
	 .player_shot	   ( player_shot ),
	 .player_hit		( player_hit ),
	 .invader_hit		( invader_hit ),
	 .march1				( march1 ),
	 .march2				( march2 ),
	 .march3				( march3 ),
	 .march4				( march4 ),
	 .ufo_hit			( ufo_hit ),
	 .extended_play	( extended_play ),
	 .audio_data		( audio_data )
);

endmodule
