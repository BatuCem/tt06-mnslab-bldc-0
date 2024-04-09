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
    input clk,
    input rst,
    output div_clk
    );
    reg [7:0] counter= 8'b0;
    assign div_clk = counter[1];
    always @(posedge clk)begin
        if (rst)begin
            counter <= counter + 1;
        end
        else begin
            counter <= counter + 1;
        end
    end
endmodule
