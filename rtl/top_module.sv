
module top(

    input clk,
    input reset,


    input [7:0] hall_up_request,
    input [7:0] hall_down_request,

    input [7:0] floor_request1,
    input [7:0] floor_request2,

    input [7:0] weight1,
    input [7:0] weight2,


    input emergency1,
    input emergency2,

    input obstruction1,
    input obstruction2,

    input fire_alarm1,
    input fire_alarm2,

    input door_hold1,
    input door_hold2,

    input maintenance_mode1,
    input maintenance_mode2,

    output [2:0] current_floor1,
    output [2:0] floor_display1,

    output moving_up1,
    output moving_down1,

    output door_open1,
    output bell1,
    output door_led1,
    output alarm1,

    output [2:0] current_floor2,
    output [2:0] floor_display2,

    output moving_up2,
    output moving_down2,

    output door_open2,
    output bell2,
    output door_led2,
    output alarm2

);


// Dispatcher wires


wire [7:0] hall_up_to_e1;
wire [7:0] hall_up_to_e2;

wire [7:0] hall_down_to_e1;
wire [7:0] hall_down_to_e2;

wire elevator1_busy;
wire elevator2_busy;

wire elevator1_served;
wire [2:0] elevator1_served_floor;
wire elevator1_served_up;
wire elevator1_served_down;

    // Elevator 2 Served Signals

wire elevator2_served;
wire [2:0] elevator2_served_floor;
wire elevator2_served_up;
wire elevator2_served_down;



// Busy Logic
assign elevator1_busy = moving_up1 | moving_down1 | door_open1;
assign elevator2_busy = moving_up2 | moving_down2 | door_open2;



// Dispatcher

dispatcher dispatcher_inst(

    .clk(clk),
    .reset(reset),

    .elevator1_floor(current_floor1),
    .elevator2_floor(current_floor2),

    .elevator1_busy(elevator1_busy),
    .elevator2_busy(elevator2_busy),

    .elevator1_up(moving_up1),
    .elevator1_down(moving_down1),

    .elevator2_up(moving_up2),
    .elevator2_down(moving_down2),

    .hall_up_request(hall_up_request),
    .hall_down_request(hall_down_request),

    .hall_up_to_e1(hall_up_to_e1),
    .hall_up_to_e2(hall_up_to_e2),

    .hall_down_to_e1(hall_down_to_e1),
    .hall_down_to_e2(hall_down_to_e2),

    .elevator1_served(elevator1_served),
    .elevator1_served_floor(elevator1_served_floor),
    .elevator1_served_up(elevator1_served_up),
    .elevator1_served_down(elevator1_served_down),

    .elevator2_served(elevator2_served),
    .elevator2_served_floor(elevator2_served_floor),
    .elevator2_served_up(elevator2_served_up),
    .elevator2_served_down(elevator2_served_down)

);


elevator_controller elevator1(

    .clk(clk),
    .reset(reset),

    .floor_request(floor_request1),

    .hall_up_request(hall_up_to_e1),
    .hall_down_request(hall_down_to_e1),

    .weight(weight1),

    .current_floor(current_floor1),
    .floor_display(floor_display1),

    .moving_up(moving_up1),
    .moving_down(moving_down1),

    .door_open(door_open1),

    .bell(bell1),
    .door_led(door_led1),

    .emergency(emergency1),
    .obstruction(obstruction1),
    .fire_alarm(fire_alarm1),
    .door_hold(door_hold1),
    .maintenance_mode(maintenance_mode1),

    .alarm(alarm1),

    .served(elevator1_served),
    .served_floor(elevator1_served_floor),
    .served_up(elevator1_served_up),
    .served_down(elevator1_served_down)

);


elevator_controller elevator2(

    .clk(clk),
    .reset(reset),

    .floor_request(floor_request2),

    .hall_up_request(hall_up_to_e2),
    .hall_down_request(hall_down_to_e2),

    .weight(weight2),

    .current_floor(current_floor2),
    .floor_display(floor_display2),

    .moving_up(moving_up2),
    .moving_down(moving_down2),

    .door_open(door_open2),

    .bell(bell2),
    .door_led(door_led2),

    .emergency(emergency2),
    .obstruction(obstruction2),
    .fire_alarm(fire_alarm2),
    .door_hold(door_hold2),
    .maintenance_mode(maintenance_mode2),

    .alarm(alarm2),

    .served(elevator2_served),
    .served_floor(elevator2_served_floor),
    .served_up(elevator2_served_up),
    .served_down(elevator2_served_down)

);

endmodule
