`timescale 1ns/1ps

module tb1;

reg clk;
reg reset;

reg [7:0] hall_up_request;
reg [7:0] hall_down_request;

reg [7:0] floor_request1;
reg [7:0] floor_request2;

reg [7:0] weight1;
reg [7:0] weight2;

reg emergency1;
reg emergency2;

reg obstruction1;
reg obstruction2;

reg fire_alarm1;
reg fire_alarm2;

reg door_hold1;
reg door_hold2;

reg maintenance_mode1;
reg maintenance_mode2;

wire [2:0] current_floor1;
wire [2:0] floor_display1;
wire moving_up1;
wire moving_down1;
wire door_open1;
wire bell1;
wire door_led1;
wire alarm1;

wire [2:0] current_floor2;
wire [2:0] floor_display2;
wire moving_up2;
wire moving_down2;
wire door_open2;
wire bell2;
wire door_led2;
wire alarm2;


// DUT

top dut (

    .clk(clk),
    .reset(reset),

    .hall_up_request(hall_up_request),
    .hall_down_request(hall_down_request),

    .floor_request1(floor_request1),
    .floor_request2(floor_request2),

    .weight1(weight1),
    .weight2(weight2),

    .emergency1(emergency1),
    .emergency2(emergency2),

    .obstruction1(obstruction1),
    .obstruction2(obstruction2),

    .fire_alarm1(fire_alarm1),
    .fire_alarm2(fire_alarm2),

    .door_hold1(door_hold1),
    .door_hold2(door_hold2),

    .maintenance_mode1(maintenance_mode1),
    .maintenance_mode2(maintenance_mode2),

    .current_floor1(current_floor1),
    .floor_display1(floor_display1),
    .moving_up1(moving_up1),
    .moving_down1(moving_down1),
    .door_open1(door_open1),
    .bell1(bell1),
    .door_led1(door_led1),
    .alarm1(alarm1),

    .current_floor2(current_floor2),
    .floor_display2(floor_display2),
    .moving_up2(moving_up2),
    .moving_down2(moving_down2),
    .door_open2(door_open2),
    .bell2(bell2),
    .door_led2(door_led2),
    .alarm2(alarm2)

);



// CLOCK


always #5 clk = ~clk;

// MAIN TEST

initial begin

    $dumpfile("dump.vcd");
    $dumpvars(0, tb1);

    clk = 0;
    reset = 1;

    hall_up_request   = 8'b0;
    hall_down_request = 8'b0;

    floor_request1 = 8'b0;
    floor_request2 = 8'b0;

    weight1 = 8'b0;
    weight2 = 8'b0;

    emergency1 = 0;
    emergency2 = 0;

    obstruction1 = 0;
    obstruction2 = 0;

    fire_alarm1 = 0;
    fire_alarm2 = 0;

    door_hold1 = 0;
    door_hold2 = 0;

    maintenance_mode1 = 0;
    maintenance_mode2 = 0;


    // RESET
    
    #20;

    reset = 0;


// TEST 1 : TWO-WAY HALL CALL AT SAME FLOOR



$display("TEST 1 : UP + DOWN REQUESTS AT FLOOR 2");

@(negedge clk);

hall_up_request[2]   = 1'b1;
hall_down_request[2] = 1'b1;

@(negedge clk);

hall_up_request[2]   = 1'b0;
hall_down_request[2] = 1'b0;

#100;



// TEST 2 : PASSENGER ENTERS ELEVATOR 1
// Internal request: Floor 6

$display("");
$display("TEST 2 : E1 PASSENGER -> FLOOR 6");

floor_request1[6] = 1'b1;

#10;

floor_request1 = 8'b0;



// TEST 3 : REQUESTS WHILE E1 IS MOVING


#50;

$display("");
$display("TEST 3 : NEW HALL REQUESTS DURING MOVEMENT");

@(negedge clk);

hall_down_request[4] = 1'b1;
hall_up_request[5]   = 1'b1;

@(negedge clk);

hall_down_request[4] = 1'b0;
hall_up_request[5]   = 1'b0;



// TEST 4 : E2 INTERNAL REQUEST


#80;

$display("");
$display("TEST 4 : E2 PASSENGER -> FLOOR 3");

floor_request2[3] = 1'b1;

#10;

floor_request2 = 8'b0;

#100;


// TEST 5 : MULTIPLE SIMULTANEOUS HALL REQUESTS


$display("TEST 5 : MULTIPLE SIMULTANEOUS HALL REQUESTS");

@(negedge clk);

// Multiple UP requests
hall_up_request[1] = 1'b1;
hall_up_request[3] = 1'b1;
hall_up_request[5] = 1'b1;

// Multiple DOWN requests
hall_down_request[2] = 1'b1;
hall_down_request[4] = 1'b1;
hall_down_request[6] = 1'b1;

@(negedge clk);

// Remove external requests
hall_up_request   = 8'b0;
hall_down_request = 8'b0;

$display("UP requests  : Floors 1, 3, 5");
$display("DOWN requests: Floors 2, 4, 6");


// Allow dispatcher to assign requests


#150;



// TEST 5A : MORE REQUESTS WHILE BOTH ELEVATORS ARE ALREADY BUSY


$display("TEST 5A : NEW REQUESTS DURING ELEVATOR MOVEMENT");

@(negedge clk);

// New UP requests
hall_up_request[0] = 1'b1;
hall_up_request[7] = 1'b1;

// New DOWN requests
hall_down_request[1] = 1'b1;
hall_down_request[5] = 1'b1;

@(negedge clk);

hall_up_request   = 8'b0;
hall_down_request = 8'b0;

$display("New UP requests  : Floors 0, 7");
$display("New DOWN requests: Floors 1, 5");



// TEST 5B : INTERNAL CAR REQUESTS WHILE HALL REQUESTS ARE PENDING


#100;

$display("");
$display("TEST 5B : INTERNAL FLOOR REQUESTS");

// E1 passenger selects Floor 7
floor_request1[7] = 1'b1;

// E2 passenger selects Floor 2
floor_request2[2] = 1'b1;

#10;

floor_request1 = 8'b0;
floor_request2 = 8'b0;

$display("E1 internal request -> Floor 7");
$display("E2 internal request -> Floor 2");

// TEST 5C : ANOTHER BURST OF HALL REQUESTS

#120;

$display("");
$display("TEST 5C : SECOND BURST OF HALL REQUESTS");

@(negedge clk);

// UP
hall_up_request[2] = 1'b1;
hall_up_request[4] = 1'b1;

// DOWN
hall_down_request[3] = 1'b1;
hall_down_request[7] = 1'b1;

@(negedge clk);

hall_up_request   = 8'b0;
hall_down_request = 8'b0;

$display("UP requests  : Floors 2, 4");
$display("DOWN requests: Floors 3, 7");
#600;

// TEST 6 : OVERLOAD


#100;

$display("");
$display("TEST 6 : OVERLOAD CONDITION");

weight1 = 8'd250;

#80;

$display("E1 Overload activated");
$display("Alarm1 = %b", alarm1);
$display("Door1  = %b", door_open1);

weight1 = 8'd100;

#80;

$display("E1 Overload cleared");



// TEST 7 : EMERGENCY


$display("");
$display("TEST 7 : EMERGENCY CONDITION");

emergency1 = 1'b1;

#100;

$display("E1 Emergency activated");
$display("Alarm1 = %b", alarm1);

emergency1 = 1'b0;

#100;

$display("E1 Emergency cleared");


// TEST 8 : FIRE ALARM


$display("");
$display("TEST 8 : FIRE ALARM");

fire_alarm1 = 1'b1;

#100;

$display("E1 Fire Alarm activated");
$display("Alarm1 = %b", alarm1);

fire_alarm1 = 1'b0;

#100;

$display("E1 Fire Alarm cleared");



// TEST 9 : DOOR OBSTRUCTION


$display("");
$display("TEST 9 : DOOR OBSTRUCTION");

obstruction1 = 1'b1;

#100;

$display("E1 Obstruction activated");
$display("Door1 = %b", door_open1);

obstruction1 = 1'b0;

#100;

$display("E1 Obstruction cleared");



// TEST 10 : DOOR HOLD



$display("TEST 10 : DOOR HOLD");

door_hold1 = 1'b1;

#100;

$display("E1 Door Hold activated");
$display("Door1 = %b", door_open1);

door_hold1 = 1'b0;

#100;

$display("E1 Door Hold released");



// TEST 11 : MAINTENANCE MODE


$display("TEST 11 : MAINTENANCE MODE");

maintenance_mode1 = 1'b1;

#100;

$display("E1 Maintenance Mode activated");


// Try a request during maintenance
floor_request1[7] = 1'b1;

#50;

floor_request1 = 8'b0;

#100;

maintenance_mode1 = 1'b0;

$display("E1 Maintenance Mode cleared");



// TEST 12 : ELEVATOR 2 EMERGENCY


$display("TEST 12 : E2 EMERGENCY");

emergency2 = 1'b1;

#100;

$display("E2 Emergency activated");
$display("Alarm2 = %b", alarm2);

emergency2 = 1'b0;

#100;

$display("E2 Emergency cleared");


// TEST 13 : ELEVATOR 2 FIRE ALARM

$display("TEST 13 : E2 FIRE ALARM");

fire_alarm2 = 1'b1;

#100;

$display("E2 Fire Alarm activated");
$display("Alarm2 = %b", alarm2);

fire_alarm2 = 1'b0;

#100;

$display("E2 Fire Alarm cleared");



// TEST 14 : NORMAL OPERATION AFTER ALL CONDITIONS


$display("TEST 14 : NORMAL OPERATION RECOVERY");

@(negedge clk);

hall_up_request[3]   = 1'b1;
hall_down_request[5] = 1'b1;

@(negedge clk);

hall_up_request[3]   = 1'b0;
hall_down_request[5] = 1'b0;

#500;


// FINAL STATUS

$display(" INTEGRATED VERIFICATION COMPLETE");

$display("ELEVATOR 1");
$display("Final Floor       = %d", current_floor1);
$display("Moving Up         = %b", moving_up1);
$display("Moving Down       = %b", moving_down1);
$display("Door Open         = %b", door_open1);
$display("Alarm             = %b", alarm1);

$display("ELEVATOR 2");
$display("Final Floor       = %d", current_floor2);
$display("Moving Up         = %b", moving_up2);
$display("Moving Down       = %b", moving_down2);
$display("Door Open         = %b", door_open2);
$display("Alarm             = %b", alarm2);


$finish;
end
endmodule
