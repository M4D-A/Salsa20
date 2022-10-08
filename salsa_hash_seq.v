module salsa_hash_seq(
    input wire clk,
    input wire start,
    input wire reset,

    output wire ready,
    output wire writes,

    input wire [31 : 0] data_in,

    output reg [7 : 0] data_out
);

reg [7 : 0] state;
reg [7 : 0] counter;
reg [511 : 0] data;
reg [511 : 0] data_copy;

assign ready = (state == 0);
assign writes = (state == 3);

initial begin
    state <= 7'b0;
    counter <= 7'b0;

    data <= 512'b0;
    data[031 : 000] <= 31'h61707865;
    data[191 : 160] <= 31'h3320646e;
    data[351 : 320] <= 31'h79622d32;
    data[511 : 480] <= 31'h6b206574;

    data_copy <= 512'h0;
end

wire [511 : 0] data_out_wire_odd;
wire [511 : 0] data_out_wire_even;

odd_round oddr(
    .d_in(data),
    .d_out(data_out_wire_odd)
);

even_round evenr(
    .d_in(data),
    .d_out(data_out_wire_even)
);

always @(posedge clk) begin
    if (reset) begin
        state <= 7'b0;
        counter <= 7'b0;
        
        data <= 512'b0;
        data[031 : 000] <= 31'h61707865;
        data[191 : 160] <= 31'h3320646e;
        data[351 : 320] <= 31'h79622d32;
        data[511 : 480] <= 31'h6b206574;
        data_copy <= 512'h0;
    end 
    
    if ((start == 1) && (state == 0)) begin // wait for data and read key[0]
        state <= 1;
        counter <= 1;
        data [63:32] <= data_in;
    end

    if (state == 1) begin //read
        counter <= counter + 1;
        if (counter == 1) begin data [95:64] <= data_in; end //key[1]
        else if (counter == 2) begin data [127:96] <= data_in; end //key[2]
        else if (counter == 3) begin data [159:128] <= data_in; end //key[3]

        else if (counter == 4) begin data [383:352] <= data_in; end //key[4]
        else if (counter == 5) begin data [415:384] <= data_in; end //key[5]
        else if (counter == 6) begin data [447:416] <= data_in; end //key[6]
        else if (counter == 7) begin data [479:448] <= data_in; end //key[7]

        else if (counter == 8) begin data [223:192] <= data_in; end //nonce[0]
        else if (counter == 9) begin data [255:224] <= data_in; end //nonce[1]

        else if (counter == 10) begin data [287:256] <= data_in; end //pos[0]
        else if (counter == 11) begin data [319:288] <= data_in;
            counter <= 0;
            state <= 2;
        end //pos[1]
    end

    if (state == 2) begin //hash
        counter <= counter + 1;

        if(counter == 0) begin
            data_copy <= data;
        end

        if(counter < 20) begin
            if(counter % 2 == 0) begin
                data <= data_out_wire_even;
            end
            else begin
                data <= data_out_wire_odd;
            end
        end

        if(counter == 20) begin
            data[511:480] <= data[511:480] + data_copy[511:480];
            data[479:448] <= data[479:448] + data_copy[479:448];
            data[447:416] <= data[447:416] + data_copy[447:416];
            data[415:384] <= data[415:384] + data_copy[415:384];
            data[383:352] <= data[383:352] + data_copy[383:352];
            data[351:320] <= data[351:320] + data_copy[351:320];
            data[319:288] <= data[319:288] + data_copy[319:288];
            data[287:256] <= data[287:256] + data_copy[287:256];
            data[255:224] <= data[255:224] + data_copy[255:224];
            data[223:192] <= data[223:192] + data_copy[223:192];
            data[191:160] <= data[191:160] + data_copy[191:160];
            data[159:128] <= data[159:128] + data_copy[159:128];
            data[127:096] <= data[127:096] + data_copy[127:096];
            data[095:064] <= data[095:064] + data_copy[095:064];
            data[063:032] <= data[063:032] + data_copy[063:032];
            data[031:000] <= data[031:000] + data_copy[031:000];
        end

        if (counter == 21) begin
            data_out <= data[7 : 0];
            data[503 : 000] <= data[511 : 008];
            data[511 : 504] <= 8'b0;
            state <= 3;
            counter <= 0;
        end
    end

    if (state == 3) begin
        data_out <= data[7 : 0];
        data[503 : 000] <= data[511 : 008];
        data[511 : 504] <= 8'b0;
        counter <= counter + 1;
        if (counter == 63) begin
            data_out <= 8'bx;
            state <= 0;
            counter <= 0;
            data <= 512'b0;
            data[031 : 000] <= 31'h61707865;
            data[191 : 160] <= 31'h3320646e;
            data[351 : 320] <= 31'h79622d32;
            data[511 : 480] <= 31'h6b206574;
        end 
    end
end

endmodule



