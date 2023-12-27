module invaders_sound (

	// Inputs
	input					  clk_audio,
	input               rst_n,
	input					  display_enable,

	output  reg           ram1_word_rd,
	output  reg				 ram1_word_wr,
	output  reg   [23:0]  ram1_word_addr,
	output  reg   [31:0]  ram1_word_data,
	input      [31:0]  ram1_word_q,
	input              ram1_word_busy,
	
	input						ufo_visible,
	input						player_shot,
	input						player_hit,
	input						invader_hit,
	input						march1,
	input						march2,
	input						march3,
	input						march4,
	input						ufo_hit,
	input						extended_play,
	
	output reg	[15:0]			audio_data			
);

always ram1_word_wr = 1'b0;
always ram1_word_data = 32'h00000000;

wire [31:0] soundram_word_q_s;
synch_3 #(.WIDTH(32)) s4(ram1_word_q, soundram_word_q_s, clk_audio);

reg [4:0] channel_counter;
reg [2:0] fetch_state;

reg sample_available[0:9];

wire [23:0] sample_pointer [0:9];
wire			sample_requested [0:9];
wire signed [15:0]	channel_audio [0:9];
always @(posedge clk_audio or negedge rst_n) begin
	reg  signed [24:0] mixed_audio;
	if (rst_n == 1'b0) begin
		audio_data <= 16'h0000;
	end else begin
		mixed_audio = channel_audio[0] + channel_audio[1] + channel_audio[2] + channel_audio[3] + channel_audio[4] + channel_audio[5] + 
							channel_audio[6] + channel_audio[7] + channel_audio[8] + channel_audio[9];
		audio_data <= mixed_audio >>> 4;
	end
end

always @(posedge clk_audio or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		ram1_word_rd <= 1'b0;
		ram1_word_addr <= 24'h000000;
		channel_counter <= 9'h00;
		fetch_state <= 3'h0;
	end else begin
		if (display_enable == 1'b1) begin
			case (fetch_state)
				0: begin
					if (sample_requested[channel_counter] == 1'b1) begin
						ram1_word_addr <= sample_pointer[channel_counter];
						ram1_word_rd <= 1'b1;
						fetch_state <= 1;
					end else begin
						fetch_state <= 6;
					end
				end
				1: begin
					ram1_word_rd <= 1'b0;
					fetch_state <= 2;
				end
				2: begin
					ram1_word_rd <= 1'b0;
					fetch_state <= 3;
				end
				3: begin
					ram1_word_rd <= 1'b0;
					fetch_state <= 4;
				end
				4:	begin
					sample_available[channel_counter] <= 1'b1;
					fetch_state <= 5;
				end
				5: begin
					sample_available[channel_counter] <= 1'b0;
					fetch_state <= 6;
				end
				6: begin
					channel_counter <= channel_counter + 1;
					if (channel_counter == 9) begin
						channel_counter <= 0;
					end
					fetch_state <= 0;
				end
			endcase
		end
	end
end

invaders_sound_channel #(
	.BASE_ADDRESS(24'h000000),
	.SAMPLES_LENGTH(24'h003afa),
	.LOOPING(1)
) sc0 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( ufo_visible ),
	.sample_available	( sample_available[0] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[0] ),
	.sample_requested	( sample_requested[0] ),
	
	.audio_data			( channel_audio[0] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h100000),
	.SAMPLES_LENGTH(24'h00776c)
) sc1 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( player_shot ),
	.sample_available	( sample_available[1] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[1] ),
	.sample_requested	( sample_requested[1] ),
	
	.audio_data			( channel_audio[1] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h200000),
	.SAMPLES_LENGTH(24'h01c90c)
) sc2 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( player_hit ),
	.sample_available	( sample_available[2] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[2] ),
	.sample_requested	( sample_requested[2] ),
	
	.audio_data			( channel_audio[2] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h300000),
	.SAMPLES_LENGTH(24'h009e12)
) sc3 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( invader_hit ),
	.sample_available	( sample_available[3] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[3] ),
	.sample_requested	( sample_requested[3] ),
	
	.audio_data			( channel_audio[3] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h400000),
	.SAMPLES_LENGTH(24'h001948)
) sc4 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( march1 ),
	.sample_available	( sample_available[4] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[4] ),
	.sample_requested	( sample_requested[4] ),
	
	.audio_data			( channel_audio[4] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h500000),
	.SAMPLES_LENGTH(24'h0016a8)
) sc5 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( march2 ),
	.sample_available	( sample_available[5] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[5] ),
	.sample_requested	( sample_requested[5] ),
	
	.audio_data			( channel_audio[5] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h600000),
	.SAMPLES_LENGTH(24'h0017d8)
) sc6 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( march3 ),
	.sample_available	( sample_available[6] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[6] ),
	.sample_requested	( sample_requested[6] ),
	
	.audio_data			( channel_audio[6] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h700000),
	.SAMPLES_LENGTH(24'h001990)
) sc7 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( march4 ),
	.sample_available	( sample_available[7] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[7] ),
	.sample_requested	( sample_requested[7] ),
	
	.audio_data			( channel_audio[7] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h800000),
	.SAMPLES_LENGTH(24'h02F88E)
) sc8 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( ufo_hit ),
	.sample_available	( sample_available[8] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[8] ),
	.sample_requested	( sample_requested[8] ),
	
	.audio_data			( channel_audio[8] ),
);

invaders_sound_channel #(
	.BASE_ADDRESS(24'h900000),
	.SAMPLES_LENGTH(24'h028D5A)
) sc9 (
	.clk_audio			( clk_audio ),
	.rst_n				( rst_n ),
	
	.channel_active	( extended_play ),
	.sample_available	( sample_available[9] ),
	.sample				( soundram_word_q_s ),
	
	.sample_pointer	( sample_pointer[9] ),
	.sample_requested	( sample_requested[9] ),
	
	.audio_data			( channel_audio[9] ),
);

endmodule

module invaders_sound_channel #(
	parameter BASE_ADDRESS = 24'h000000,
	parameter SAMPLES_LENGTH = 24'h000000,
	parameter LOOPING = 1'b0
) (

	// Inputs
	input					  clk_audio,
	input               rst_n,

	input					  channel_active,
	input					  sample_available,
	input       [31:0]  sample,
	
	output reg  [23:0]  sample_pointer,
	output reg          sample_requested,
	
	output reg	[15:0]  audio_data			
);

reg sample_playing;
reg sample_toggle;
reg [31:0] current_sample;
reg [7:0] timer_counter;
reg channel_active_p;

always @(posedge clk_audio or negedge rst_n) begin
	if (rst_n == 1'b0) begin
		sample_requested <= 1'b0;
		sample_pointer <= BASE_ADDRESS >> 2;
		audio_data <= 16'h0000;
		sample_toggle <= 1'b0;
		timer_counter <= 8'h00;
		sample_playing <= 1'b0;
	end else begin
		channel_active_p <= channel_active;
		if (channel_active == 1'b1) begin
			if (channel_active != channel_active_p) begin
				sample_playing <= 1'b1;
				sample_requested <= 1'b1;
			end
		end else begin
			sample_playing <= 1'b0;
		end
		
		if (sample_requested == 1'b1) begin
			if (sample_available == 1'b1) begin
				sample_pointer <= sample_pointer + 1;
				current_sample <= sample;
				sample_requested <= 1'b0;
				sample_toggle <= 1'b0;
			end
		end else begin
			if (sample_playing == 1'b1) begin
				audio_data <= sample_toggle ? {current_sample[23:16], current_sample[31:24]} : {current_sample[7:0], current_sample[15:8]};
				timer_counter <= timer_counter + 1;
				if (timer_counter == 8'd175) begin
					timer_counter <= 8'h00;
					if (sample_pointer == ((BASE_ADDRESS >> 2) + (SAMPLES_LENGTH >> 2))) begin
						if (LOOPING == 1'b1) begin
							sample_requested <= 1'b1;
							sample_pointer <= BASE_ADDRESS;
						end else begin
							sample_playing <= 1'b0;
						end
					end else begin
						if (sample_toggle == 1'b1) begin
							sample_requested <= 1'b1;
						end else begin
							sample_toggle <= 1'b1;
						end
					end
				end
			end else begin
				audio_data <= 16'h0000;
				sample_requested <= 1'b0;
				sample_pointer <= BASE_ADDRESS >> 2;
				sample_toggle <= 1'b0;
				timer_counter <= 8'h00;
			end
		end
	end
end

endmodule