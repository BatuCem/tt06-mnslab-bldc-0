//////////////////////////////////////////////////////////////////////////////////
// Company: Hacettepe University MNS Labs
// Engineer: 
// 
// Create Date: 17.01.2024 11:44:23
// Design Name: BLDC
// Module Name: Divided_Clock
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

module Divided_Clock(
    input clk, //25MHz clk
    input rst,
    output div_clk1,
    output div_clk2
    );
    reg [2:0] counter= 3'b0;
    assign div_clk1 = counter[0]; //25MHz divider clock
    assign div_clk2 = counter[2]; //6.25MHz esc counter clock
    always @(posedge clk)begin
        if (rst)begin
            counter <= counter + 1;
        end
        else begin
            counter <= counter + 1;
        end
    end
endmodule
