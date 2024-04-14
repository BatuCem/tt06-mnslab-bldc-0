//////////////////////////////////////////////////////////////////////////////////
// Company: Hacettepe University MNS Labs
// Engineer: 
// 
// Create Date: 17.01.2024 11:44:23
// Design Name: BLDC
// Module Name: pid_tuner
// Project Name: PID Controller for BLDC
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

 module pid_tuner #(
  parameter DATA_WIDTH = 16 //only used at the 3rd subroutine
)(
  input wire clk_div,              		// clock input. when there is no clk signal motor does not run, CLK @50MHz, T=20ns
  input wire reset,            		// when it is 1 motor does run
  input wire [2:0] pid_select,			//select control type: 100 for P, 110 for PI, 111 for PID (?)
  input wire signed [DATA_WIDTH-1:0] period_speed,//system output of speed measured in clock cycles
  output reg tuning_done,
	output reg [7:0] Kp,//proportional constant
	 output reg [7:0] Ki,//integral constant
	 output reg [6:0] Kd//derivative constant
  
  
);


	reg division_trig =1'b0;
	reg [31:0] dividend=32'd0;
	reg [31:0] divisor =32'd0;
	wire [31:0] quotient ;
	wire [31:0] remainder ;
	wire division_running;
   	reg reset_divider;
   	wire div_done;

	Divider32bit divider_inst(
   .clk(clk_div),
   .reset(reset_divider),
   .start_division(division_trig),  // Start signal for division
   .dividend(dividend),       // Dividend input
   .divisor(divisor),        // Divisor input
   .quotient(quotient),   // Quotient output
   .remainder(remainder),  // Remainder output
      .division_active(division_running),   // Declaration of division_active
      .division_done(div_done)
);

	reg [DATA_WIDTH-1:0] period_counter=16'd0;	//register for time between peaks
	reg [DATA_WIDTH-1:0] peak_period=16'd0;		//register for last time between peaks
	reg signed [DATA_WIDTH-1:0] period_speed_reg=16'd0;
	reg signed [DATA_WIDTH-1:0] prev_period_speed=16'd0;		//save previous speed
	reg signed [DATA_WIDTH-1:0] peak_level=16'd0;
	reg signed [DATA_WIDTH-1:0] prev_peak_level=16'd0;
	reg signed [DATA_WIDTH-1:0] dip_level;
    reg [7:0]	Kp_max;				//temporary Kp for incrementation and find max, init to decimal 1 
	
   //find peaks
	reg autotune_finalized=1'b0;
	reg decreasing_flag=1'b0;
	reg increasing_flag=1'b0;
	reg Kp_done;
	reg Ki_done;
	reg Kd_done;
	
	always @(posedge clk_div) begin
    if (reset) begin
		peak_period<=16'h7fff;
		Kp_done<=1'b0;
		Ki_done<=1'b0;
		Kd_done<=1'b0;
		division_trig <=1'b0;
		dividend<=32'd0;
		divisor<=32'd0;
      	period_counter<=16'd0;
      	period_speed_reg<=16'h7fff;
      	prev_period_speed<=16'h7fff;
      	peak_level<=16'h7fff;
      	prev_peak_level<=16'h7fff;
      	dip_level<=16'h0000;
      	autotune_finalized<=1'b0;
      	decreasing_flag<=1'b0;
      	increasing_flag<=1'b1;
      	Kp_max<=8'd1;
      	Kp<=8'b1;
      	Ki<=8'b0;
      	Kd<=7'b0;
      	tuning_done<=1'b0;
      	reset_divider<=1'b1;
    end else
	   begin 
	       if(autotune_finalized==1'b0)
	       begin
	           prev_period_speed<=period_speed_reg;
	           period_speed_reg<=period_speed;
	               if(prev_period_speed<=period_speed_reg)
	               begin
	                   increasing_flag<=1'b1;
	               end else if (increasing_flag==1'b1)
	               begin
	                   dip_level<=prev_period_speed;
	               end else begin
	                   increasing_flag<=1'b0;
	               end
	               if(prev_period_speed>=period_speed_reg)	//decreasing signal
	               begin
	                   decreasing_flag<=1'b1;
	                   period_counter<=period_counter+1;
	               end else if (decreasing_flag==1'b1)	//found peak
	               begin
	                   peak_period<=period_counter;	//replace current period with counted period
	                   period_counter<=16'd0;			//TODO: convert to non-blocking type
	                   prev_peak_level<=peak_level;
	                   peak_level<=prev_period_speed;	//made prev_period_speed instead of period_speed to get real peak			
	                   if (prev_peak_level!=16'h7fff) 
	                   begin
//	                       if(peak_level==prev_peak_level)	//Found oscillation Kp if peaks are at the same level (?)
//	                       begin
//					           Kp_max<=Kp_max+1;
//					       end else if (peak_level<prev_peak_level)	//decreasing period peak indicates instability, decrement Kpmax and finalize autotune
//					       begin
//					           Kp_max<=Kp_max-1;
//					           autotune_finalized<=1'b1;
//					       end else begin	//increasing period peaks, increment Kpmax for more oscillation
//					           Kp_max<=Kp_max+1;
//					       end
                           if(dip_level>=0 && peak_level<=0)
                           begin
                               Kp_max<=Kp_max+1;
                           end else begin
                               Kp_max<=Kp_max-1;
                               autotune_finalized<=1'b1;
                           end
					   end else begin
					       autotune_finalized<=1'b0;
					   end
					   Kp<=Kp_max;
					   //prev_peak_flag<=peak_flag;
					   //prev_peak_flag<=peak_flag;
					   //peak_flag<=1'b1;
					   decreasing_flag<=1'b0;
                    end else begin
                        period_counter<=period_counter+1;		//count period at each clock cycle
                    end
                    //if(peak_flag==1'b1) begin	//if peak is found, 
                    //peak_flag<=1'b0;			//reset peak found flag
                end else begin
                    //TODO:set outputs for different cases
					case (pid_select)
					   3'b100: begin //SELECT PROPORTIONAL CONTROL
						  Kp<=Kp_max>>1;	//right shift (div by 2) Kpmax to get Kp
						  Kp_done<=1'b1;
						  Ki<=0;
						  Ki_done<=1'b1;
						  Kd<=0;
						  Kd_done<=1'b1;
					   end
					   3'b110: begin //SELECT PROPORTIONAL-INTEGRAL CONTROL
						  if(Kp_done!=1'b1)
						  begin
						      //Kp<=Kp_max*45/100;
						      if(division_trig==1'b0)
						      begin
                                reset_divider<=1'b1;
								dividend<=45*Kp_max;
								divisor<=100;
								division_trig<=1'b1;
							 end else if (div_done==1'b1) begin
								Kp<=quotient[7:0];
								division_trig<=1'b0;
								Kp_done<=1'b1;
							end else begin
                              	reset_divider<=1'b0;
                            end
                        end else if (Ki_done!=1'b1)
					       begin
					           //Ki<=54*Kp_max/(peak_period*100)
					           if(division_trig==1'b0)
					           begin
							        dividend<=54*Kp_max;
								    divisor<=100*peak_period;
								    division_trig<=1'b1;
							   end else if (div_done==1'b1) begin
								    Ki<=quotient[7:0];
								    division_trig<=1'b0;
								    Ki_done<=1'b1;
							   end else begin
							        reset_divider<=1'b1;
							   end
						  end
						Kd<=0;
						Kd_done<=1'b1;
					end
					3'b111: begin //SELECT PROPORTIONA-INTEGRAL-DERIVATIVE CONTROL
						if(Kp_done!=1'b1)
						begin
							//Kp<=Kp_max*6/10;
							if(division_trig==1'b0)
							begin
                              	reset_divider<=1'b1;
								dividend<=6*Kp_max;
								divisor<=10;
								division_trig<=1'b1;
                            end else if (div_done==1'b1) begin
								Kp<=quotient[7:0];
								division_trig<=1'b0;
								Kp_done<=1'b1;
							end else begin
                              	reset_divider<=1'b0;
                            end
							end else if (Ki_done!=1'b1)
							begin
								
							//Ki<=12*Kp_max/(peak_period*10);
								if(division_trig==1'b0)
							begin
                              	
                              	reset_divider<=1'b1;
								dividend<=12*Kp_max;
								divisor<=10*peak_period;
								division_trig<=1'b1;
                            end else if (div_done) begin
								Ki<=quotient[7:0];
								division_trig<=1'b0;
								Ki_done<=1'b1;
							end else begin
                              	reset_divider<=1'b0;
                            end
							end else if (Kd_done!=1'b1)
							begin
								//Kd<=3*Kp_max*peak_period/40;
								if(division_trig==1'b0)
							begin
                              	reset_divider<=1'b01;
                              	dividend<=(3*Kp_max*peak_period)>>2;
								divisor<=10;
								division_trig<=1'b1;
							end else if (div_done) begin
                              	
								Kd<=quotient[7:0];
								division_trig<=1'b0;
								Kd_done<=1'b1;
							end else begin
                              	reset_divider<=1'b0;
                            end
							end
					end
					default:begin
						Kp<=0;	//STOP PID operation in case of invalid input
						Ki<=0;
						Kd<=0;
						Kp_done<=1'b1;
						Ki_done<=1'b1;
						Kd_done<=1'b1;
					end
					endcase
					tuning_done<=Kp_done & Ki_done & Kd_done;
            end		
    	end
	       
	end 
	
  //(* mark_debug = "true" *) wire [15:0] Kp_max;
  //(* mark_debug = "true" *) wire [15:0] peak_period;
  
	

endmodule 


