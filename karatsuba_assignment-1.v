
/* 32-bit simple karatsuba multiplier */

/*32-bit Karatsuba multipliction using a single 16-bit module*/

module iterative_karatsuba_32_16(clk, rst, enable, A, B, C);
    input clk;
    input rst;
    input [31:0] A;
    input [31:0] B;
    output [63:0] C;
    
    input enable;
    
    
    wire [1:0] sel_x;
    wire [1:0] sel_y;
    
    wire [1:0] sel_z;
    wire [1:0] sel_T;
    
    
    wire done;
    wire en_z;
    wire en_T;
    
    
    wire [32:0] h1;
    wire [32:0] h2;
    wire [63:0] g1;
    wire [63:0] g2;
    
    assign C = g2;
    reg_with_enable #(.N(64)) Z(.clk(clk), .rst(rst), .en(en_z), .X(g1), .O(g2) );  // Fill in the proper size of the register
    reg_with_enable #(.N(33)) T(.clk(clk), .rst(rst), .en(en_T), .X(h1), .O(h2) );  // Fill in the proper size of the register
    
    iterative_karatsuba_datapath dp(.clk(clk), .rst(rst), .X(A), .Y(B), .Z(g2), .T(h2), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done), .W1(g1), .W2(h1));
    iterative_karatsuba_control control(.clk(clk),.rst(rst), .enable(enable), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done));
    
endmodule

module iterative_karatsuba_datapath(clk, rst, X, Y, T, Z, sel_x, sel_y, en_z, sel_z, en_T, sel_T, done, W1, W2);
    input clk;
    input rst;
    input [31:0] X;    // input X
    input [31:0] Y;    // Input Y
    input [32:0] T;    // input which sums X_h*Y_h and X_l*Y_l (its also a feedback through the register)
    input [63:0] Z;    // input which calculates the final outcome (its also a feedback through the register)
    output [63:0] W1;  // Signals going to the registers as input
    output [32:0] W2;  // signals hoing to the registers as input
    

    input [1:0] sel_x;  // control signal 
    input [1:0] sel_y;  // control signal 
    
    input en_z;         // control signal 
    input [1:0] sel_z;  // control signal 
    input en_T;         // control signal 
    input [1:0] sel_T;  // control signal 
    
    input done;         // Final done signal
    
    wire [15:0] hx, hy, lx, ly, s1, s2;
    wire dummy_1;
    wire neg_x, neg_y;
    assign lx = X[15:0];
    assign ly = Y[15:0];
    assign hx = X[31:16];
    assign hy = Y[31:16];

    // calculating (hx - lx) and (hy - ly)

    subtract_Nbit #(16) sub_1(lx, hx, 1'b0, s1, dummy_1, neg_x);
    subtract_Nbit #(16) sub_2(hy, ly, 1'b0, s2, dummy_1, neg_y);

    // finding the modulus of the result

    wire [15:0] comp_subx, comp_suby, mod_subx, mod_suby;
    Complement2_Nbit #(16) comp1(s1, comp_subx, dummy_1);
    Complement2_Nbit #(16) comp2(s2, comp_suby, dummy_1);

    assign mod_subx = neg_x ? s1 : comp_subx;
    assign mod_suby = neg_y ? s2 : comp_suby;

    // choosing the operands

    wire [15:0] m1, m2;

    assign m1 = ((sel_x[0] & sel_x[1]) ? mod_subx : ((sel_x[0]) ?  lx : (sel_x[1] ? hx : 16'b0)));
    assign m2 = ((sel_x[0] & sel_x[1]) ? mod_suby : ((sel_x[0]) ?  ly : (sel_x[1] ? hy : 16'b0)));

    wire [31:0] pdt;

    mult_16 m_16(m1, m2, pdt);

    // adding stuff to the 33 bit reg

    wire [32:0] op1_32, op2_32, sum_32;

    wire [32:0] pdt_comp;
    Complement2_Nbit #(33) completmenter({1'b0, pdt}, pdt_comp, dummy_1);

    assign op1_32 = T;
    assign op2_32 = (((sel_x[0] ^ sel_x[1]) | (sel_x[0] & sel_x[1] & (~(neg_x ^ neg_y)))) ? {1'b0, pdt} : (((sel_x[0] & sel_x[1]) ? pdt_comp : 33'b0)));

    wire overflow;
    adder_Nbit #(33) add1(op1_32, op2_32, 1'b0, sum_32, dummy_1);
    
    assign W2 = sum_32;

    // adding stuff to the final Z register

    wire [63:0] si_32, si_16, result_16, result_32;
    
    assign si_32 = (sel_x[1] & ~sel_x[0]) ?  pdt : 64'b0;
    assign si_16 = (sel_x[1] & sel_x[0]) ?  W2 : 64'b0;

    Left_barrel_Nbit #(64) shift_32(si_32, 6'b100000, result_32);
    Left_barrel_Nbit #(64) shift_16(si_16, 6'b010000, result_16);

    wire [63:0] op1_64, op2_64, sum_64;

    assign op1_64 = Z;
    assign op2_64 = (sel_x[0] & sel_x[1] ? result_16 : (sel_x[0] ?  pdt : (sel_x[1] ? result_32 : 64'b0)));

    adder_Nbit #(64) add2(op1_64, op2_64, 1'b0, sum_64, dummy_1);
    
    assign W1 = sum_64;

   
    
    //-------------------------------------------------------------------------------------------------
    
    // Write your datapath here
    //--------------------------------------------------------

endmodule


module iterative_karatsuba_control(clk,rst, enable, sel_x, sel_y, sel_z, sel_T, en_z, en_T, done);
    input clk;
    input rst;
    input enable;
    
    output reg [1:0] sel_x;
    output reg [1:0] sel_y;
    
    output reg [1:0] sel_z;
    output reg [1:0] sel_T;    
    
    output reg en_z;
    output reg en_T;
    
    
    output reg done;
    
    reg [5:0] state, nxt_state;
    parameter S0 = 6'b000001;   // initial state
   // <define the rest of the states here>
    parameter S1 = 6'b000010;   // z0
    parameter S2 = 6'b000100;   // z2
    parameter S3 = 6'b001000;   // z1
    parameter S4 = 6'b010000;   // done
    always @(posedge clk) begin
        if (rst) begin
            state <= S0;
        end
        else if (enable) begin
            state <= nxt_state;
        end
    end
    

    always@(*) begin
        case(state) 
            S0: 
                begin
                    done = 1'b0;
                    nxt_state = S1;
                    en_T = 1'b1;
                    en_z = 1'b1;
                    sel_x = 2'b00;
                end
            S1: 
                begin
                    sel_x = 2'b01;
                    nxt_state = S2;
                end
            S2: 
                begin
					sel_x = 2'b10;
                    nxt_state = S3;
                end
            S3: 
                begin
					sel_x = 2'b11;
                    nxt_state = S4;
                end
            S4: 
                begin
                    en_T = 1'b0;
                    en_z = 1'b0;
					done = 1'b1; 
                    nxt_state = S4;
                end
            default: 
                begin
                    nxt_state = S0;
                end            
        endcase
        
    end

endmodule


module reg_with_enable #(parameter N = 32) (clk, rst, en, X, O );
    input [N-1:0] X;
    input clk;
    input rst;
    input en;
    output [N-1:0] O;
    
    reg [N-1:0] R;
    
    always@(posedge clk) begin
        if (rst) begin
            R <= {N{1'b0}};
        end
        if (en) begin
            R <= X;
        end
    end
    assign O = R;
endmodule







/*-------------------Supporting Modules--------------------*/
/*------------- Iterative Karatsuba: 32-bit Karatsuba using a single 16-bit Module*/

module mult_16(X, Y, Z);
input [15:0] X;
input [15:0] Y;
output [31:0] Z;

assign Z = X*Y;

endmodule


module mult_17(X, Y, Z);
input [16:0] X;
input [16:0] Y;
output [33:0] Z;

assign Z = X*Y;

endmodule

module full_adder(a, b, cin, S, cout);
input a;
input b;
input cin;
output S;
output cout;

assign S = a ^ b ^ cin;
assign cout = (a&b) ^ (b&cin) ^ (a&cin);

endmodule


module check_subtract (A, B, C);
 input [7:0] A;
 input [7:0] B;
 output [8:0] C;
 
 assign C = A - B; 
endmodule



/* N-bit RCA adder (Unsigned) */
module adder_Nbit #(parameter N = 32) (a, b, cin, S, cout);
input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output cout;

wire [N:0] cr;  

assign cr[0] = cin;


generate
    genvar i;
    for (i = 0; i < N; i = i + 1) begin
        full_adder addi (.a(a[i]), .b(b[i]), .cin(cr[i]), .S(S[i]), .cout(cr[i+1]));
    end
endgenerate    


assign cout = cr[N];

endmodule


module Not_Nbit #(parameter N = 32) (a,c);
input [N-1:0] a;
output [N-1:0] c;

generate
genvar i;
for (i = 0; i < N; i = i+1) begin
    assign c[i] = ~a[i];
end
endgenerate 

endmodule


/* 2's Complement (N-bit) */
module Complement2_Nbit #(parameter N = 32) (a, c, cout_comp);

input [N-1:0] a;
output [N-1:0] c;
output cout_comp;

wire [N-1:0] b;
wire ccomp;

Not_Nbit #(.N(N)) compl(.a(a),.c(b));
adder_Nbit #(.N(N)) addc(.a(b), .b({ {N-1{1'b0}} ,1'b1 }), .cin(1'b0), .S(c), .cout(ccomp));

assign cout_comp = ccomp;

endmodule


/* N-bit Subtract (Unsigned) */
module subtract_Nbit #(parameter N = 32) (a, b, cin, S, ov, cout_sub);

input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output ov;
output cout_sub;

wire [N-1:0] minusb;
wire cout;
wire ccomp;

Complement2_Nbit #(.N(N)) compl(.a(b),.c(minusb), .cout_comp(ccomp));
adder_Nbit #(.N(N)) addc(.a(a), .b(minusb), .cin(1'b0), .S(S), .cout(cout));

assign ov = (~(a[N-1] ^ minusb[N-1])) & (a[N-1] ^ S[N-1]);
assign cout_sub = cout | ccomp;

endmodule



/* n-bit Left-shift */

module Left_barrel_Nbit #(parameter N = 32)(a, n, c);

input [N-1:0] a;
input [$clog2(N)-1:0] n;
output [N-1:0] c;


generate
genvar i;
for (i = 0; i < $clog2(N); i = i + 1 ) begin: stage
    localparam integer t = 2**i;
    wire [N-1:0] si;
    if (i == 0) 
    begin 
        assign si = n[i]? {a[N-t:0], {t{1'b0}}} : a;
    end    
    else begin 
        assign si = n[i]? {stage[i-1].si[N-t:0], {t{1'b0}}} : stage[i-1].si;
    end
end
endgenerate

assign c = stage[$clog2(N)-1].si;

endmodule




// /* 32-bit simple karatsuba multiplier */

// /*32-bit Karatsuba multipliction using a single 16-bit module*/

// module iterative_karatsuba_32_16(clk, rst, enable, A, B, C);
//     input clk;
//     input rst;
//     input [31:0] A;
//     input [31:0] B;
//     output [63:0] C;
    
//     input enable;
    
    
//     wire [1:0] sel_x;
//     wire [1:0] sel_y;
    
//     wire [1:0] sel_z;
//     wire [1:0] sel_T;
    
    
//     wire done;
//     wire en_z;
//     wire en_T;
    
    
//     wire [32:0] h1;
//     wire [32:0] h2;
//     wire [63:0] g1;
//     wire [63:0] g2;
    
//     assign C = g2;
//     reg_with_enable #(.N(64)) Z(.clk(clk), .rst(rst), .en(en_z), .X(g1), .O(g2) );  // Fill in the proper size of the register
//     reg_with_enable #(.N(33)) T(.clk(clk), .rst(rst), .en(en_T), .X(h1), .O(h2) );  // Fill in the proper size of the register
    
//     iterative_karatsuba_datapath dp(.clk(clk), .rst(rst), .X(A), .Y(B), .Z(g2), .T(h2), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done), .W1(g1), .W2(h1));
//     iterative_karatsuba_control control(.clk(clk),.rst(rst), .enable(enable), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done));
    
// endmodule

// module iterative_karatsuba_datapath(clk, rst, X, Y, T, Z, sel_x, sel_y, en_z, sel_z, en_T, sel_T, done, W1, W2);
//     input clk;
//     input rst;
//     input [31:0] X;    // input X
//     input [31:0] Y;    // Input Y
//     input [32:0] T;    // input which sums X_h*Y_h and X_l*Y_l (its also a feedback through the register)
//     input [63:0] Z;    // input which calculates the final outcome (its also a feedback through the register)
//     output [63:0] W1;  // Signals going to the registers as input
//     output [32:0] W2;  // signals hoing to the registers as input
    

//     input [1:0] sel_x;  // control signal 
//     input [1:0] sel_y;  // control signal 
    
//     input en_z;         // control signal 
//     input [1:0] sel_z;  // control signal 
//     input en_T;         // control signal 
//     input [1:0] sel_T;  // control signal 
    
//     input done;         // Final done signal
    
//     wire temp0;
//     reg [15:0] m1;
//     reg [15:0] m2;

//     wire [15:0] hx, hy, lx, ly, p1, p2;
//     assign lx = X[15:0];
//     assign ly = Y[15:0];
//     assign hx = X[31:16];
//     assign hy = Y[31:16];

//     wire [15:0] s1, s2;
//     wire neg_x, neg_y;


//     // adder_Nbit #(17) ({1'b0, X[15:0]}, {1'b0, X[31:16]}, 1b'0, t1, temp);
//     // adder_Nbit #(17) ({1'b0, Y[15:0]}, {1'b0, Y[31:16]}, 1'b0, t2, temp);

//     subtract_Nbit #(17) ({1'b0, hx}, {1'b0, lx}, 1'b0, s1, ov1, cout_sub1);
//     subtract_Nbit #(17) ({1'b0, ly}, {1'b0, hy}, 1'b0, s2, ov2, cout_sub2);
    
//     //-------------------------------------------------------------------------------------------------
    

//     assign p1 = lx ? sel_x[0] & ~(sel_x[1]): 16{1'b0}; 
//     assign p2 = ly ? sel_y[0] & ~(sel_y[1]) : 16{1'b0};

//     wire dum1, dum2;

//     always @(sel_x or sel_y) begin
//         case (sel_x)
//             2'b01 : begin
//                 m1 = lx;
//             end
//             2'b10 : begin
//                 m1 = hx;
//             end
//             2'b11 : begin
//                 // m1 = s1[15:0];
//                 dum1 = s1[16];
//                 case (dum1)
//                     1 : begin
//                         Complement2_Nbit #(16) (s1[15:0], m1, dum1);
//                     end 
//                     2 :begin
                        
//                     end
//                 endcase
                    
//                 end
            

//         endcase

//         case (sel_y)
//             2'b01 : begin
//                 m2 = ly;
//             end
//             2'b10 : begin
//                 m2 = hy;
//             end
//             2'b11 : begin
//                 // m2 = s2[15:0];
//                 dum2 = s2[16];
//                 if (dum2) begin
//                     Complement2_Nbit #(16) (s2[15:0], m2, dum1);
//                 end
//             end

//         endcase

//     end

    
//     // Write your datapath here\
//     // always @(sel_x or sel_y) begin
//     //     case (sel_x)
//     //         2'b01 : begin
//     //             Complement2_Nbit c({1'b0, X[15:0]}, m1, temp0);
//     //         end 
//     //         2'b10: begin
//     //             Complement2_Nbit c({1'b0, X[31:16]}, m1, temp0);
//     //             m1[16] = 0;

//     //         end
//     //         2'b11: begin
//     //             m1 = t1;
//     //         end
//     //         default: m1 = 17'b000000000000000000; 
//     //     endcase

//     //     case (sel_y)
//     //         2'b01 : begin
//     //             m2 = Y[15:0];
//     //             m2[16] = 0;
//     //         end 
//     //         2'b10: begin
//     //             m2 = Y[31:16];
//     //             m2[16] = 0;
//     //         end
//     //         2'b11: begin
//     //             m2 = t2;
//     //         end
//     //         default: m2 = 17'b000000000000000000; 
//     //     endcase
//     // end

//     wire [31:0] pdt;

//     mult_16 m(m1, m2, pdt);

//     wire [32:0] temp;

//     assign temp = T;

//     adder_Nbit #(33) (temp, pdt, 1'b0, W2, dum1);

//     // enable the T select after this. 

//     reg [63:0] temp1, temp2;

//     always @(sel_x or sel_y) begin
//         case (sel_z)
//             1 : begin
//                 temp1 = Z;
//                 Left_barrel_Nbit #(64) l(pdt, 32, temp2);
//                 adder_Nbit #(64) l2(temp2, temp1, 1'b0, W1, dum1);
//             end
//             2 : begin
//                 temp1 = Z;
//                 adder_Nbit #(64) a2(temp1, W2, 1'b0, W1, cout); 
//             end
//             3 : begin
//                 temp1 = Z;
//                 Left_barrel_Nbit #(48) l(pdt, 16, temp2);
//                 adder_Nbit #(64) l2({ {16{1'b0}}, temp2}, temp1, 1'b0, W1, dum1);
//             end
//             default: W1 = {64{1'b0}}
//         endcase
//     end 

    

//     // enable the switch here to h2 from h1

//     // wire [32:0] sum;
//     // wire cout;
//     // adder_Nbit #(33) a(W2, T, 0, sum, cout);

//     // always @(W2 or some_enable) begin
//     //     adder_Nbit #(33) a(W2, T, 0, sum, cout);
//     //     T = sum;
//     // end

//     // always @(some_enable) begin
//     //     case (some_enable)
//     //         z2: begin
//     //             Left_barrel_Nbit #(64) l(W2, 32, W1);
//     //         end
//     //         z0: begin
//     //             wire [63:0] temp1;
//     //             assign temp1 = W1;
//     //             adder_Nbit #(64) a2(temp1, W2, 1'b0, W1, cout); 
//     //         end
//     //         z1: begin
//     //             wire [63:0] temp2;
//     //             assign temp2 = W1;
//     //             Left_barrel_Nbit #(64) l2(W2, 16, temp2);
//     //             adder_Nbit #(64) a2(temp2, W2, 1'b0, W1, cout); // have to chec k values

//     //         end 
//     //         default: W1 = 64'b000000000000000000000000000000000000000000000000000000000000000000000000;
//     //     endcase
//     // end 


//     wire temp;

    

//     //--------------------------------------------------------

// endmodule


// module iterative_karatsuba_control(clk,rst, enable, sel_x, sel_y, sel_z, sel_T, en_z, en_T, done);
//     input clk;
//     input rst;
//     input enable;
    
//     output reg [1:0] sel_x;
//     output reg [1:0] sel_y;
    
//     output reg [1:0] sel_z;
//     output reg [1:0] sel_T;    
    
//     output reg en_z;
//     output reg en_T;
    
    
//     output reg done;
    
//     reg [5:0] state, nxt_state;
//     parameter S0 = 6'b000001;   // initial state
//    // <define the rest of the states here>

//     always @(posedge clk) begin
//         if (rst) begin
//             state <= S0;
//         end
//         else if (enable) begin
//             state <= nxt_state;
//         end
//     end
    

//     always@(*) begin
//         case(state) 
//             S0: 
//                 begin
// 					// Write your output and next state equations here
//                 end
// 			// Define the rest of the states
//             default: 
//                 begin
// 				// Don't forget the default
//                 end            
//         endcase
        
//     end

// endmodule


// module reg_with_enable #(parameter N = 32) (clk, rst, en, X, O );
//     input [N-1:0] X;
//     input clk;
//     input rst;
//     input en;
//     output [N-1:0] O;
    
//     reg [N:0] R;
    
//     always@(posedge clk) begin
//         if (rst) begin
//             R <= {N{1'b0}};
//         end
//         if (en) begin
//             R <= X;
//         end
//     end
//     assign O = R;
// endmodule







// /*-------------------Supporting Modules--------------------*/
// /*------------- Iterative Karatsuba: 32-bit Karatsuba using a single 16-bit Module*/

// module mult_16(X, Y, Z);
// input [15:0] X;
// input [15:0] Y;
// output [31:0] Z;

// assign Z = X*Y;

// endmodule


// module mult_17(X, Y, Z);
// input [16:0] X;
// input [16:0] Y;
// output [33:0] Z;

// assign Z = X*Y;

// endmodule

// module full_adder(a, b, cin, S, cout);
// input a;
// input b;
// input cin;
// output S;
// output cout;

// assign S = a ^ b ^ cin;
// assign cout = (a&b) ^ (b&cin) ^ (a&cin);

// endmodule


// module check_subtract (A, B, C);
//  input [7:0] A;
//  input [7:0] B;
//  output [8:0] C;
 
//  assign C = A - B; 
// endmodule



// /* N-bit RCA adder (Unsigned) */
// module adder_Nbit #(parameter N = 32) (a, b, cin, S, cout);
// input [N-1:0] a;
// input [N-1:0] b;
// input cin;
// output [N-1:0] S;
// output cout;

// wire [N:0] cr;  

// assign cr[0] = cin;


// generate
//     genvar i;
//     for (i = 0; i < N; i = i + 1) begin
//         full_adder addi (.a(a[i]), .b(b[i]), .cin(cr[i]), .S(S[i]), .cout(cr[i+1]));
//     end
// endgenerate    


// assign cout = cr[N];

// endmodule


// module Not_Nbit #(parameter N = 32) (a,c);
// input [N-1:0] a;
// output [N-1:0] c;

// generate
// genvar i;
// for (i = 0; i < N; i = i+1) begin
//     assign c[i] = ~a[i];
// end
// endgenerate 

// endmodule


// /* 2's Complement (N-bit) */
// module Complement2_Nbit #(parameter N = 32) (a, c, cout_comp);

// input [N-1:0] a;
// output [N-1:0] c;
// output cout_comp;

// wire [N-1:0] b;
// wire ccomp;

// Not_Nbit #(.N(N)) compl(.a(a),.c(b));
// adder_Nbit #(.N(N)) addc(.a(b), .b({ {N-1{1'b0}} ,1'b1 }), .cin(1'b0), .S(c), .cout(ccomp));

// assign cout_comp = ccomp;

// endmodule


// /* N-bit Subtract (Unsigned) */
// module subtract_Nbit #(parameter N = 32) (a, b, cin, S, ov, cout_sub);

// input [N-1:0] a;
// input [N-1:0] b;
// input cin;
// output [N-1:0] S;
// output ov;
// output cout_sub;

// wire [N-1:0] minusb;
// wire cout;
// wire ccomp;

// Complement2_Nbit #(.N(N)) compl(.a(b),.c(minusb), .cout_comp(ccomp));
// adder_Nbit #(.N(N)) addc(.a(a), .b(minusb), .cin(1'b0), .S(S), .cout(cout));

// assign ov = (~(a[N-1] ^ minusb[N-1])) & (a[N-1] ^ S[N-1]);
// assign cout_sub = cout | ccomp;

// endmodule



// /* n-bit Left-shift */

// module Left_barrel_Nbit #(parameter N = 32)(a, n, c);

// input [N-1:0] a;
// input [$clog2(N)-1:0] n;
// output [N-1:0] c;


// generate
// genvar i;
// for (i = 0; i < $clog2(N); i = i + 1 ) begin: stage
//     localparam integer t = 2**i;
//     wire [N-1:0] si;
//     if (i == 0) 
//     begin 
//         assign si = n[i]? {a[N-t:0], {t{1'b0}}} : a;
//     end    
//     else begin 
//         assign si = n[i]? {stage[i-1].si[N-t:0], {t{1'b0}}} : stage[i-1].si;
//     end
// end
// endgenerate

// assign c = stage[$clog2(N)-1].si;

// endmodule



