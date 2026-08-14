


module elevator_controller(

    input clk,
    input reset,

    input [7:0] floor_request,
    input [7:0] hall_up_request,
    input [7:0] hall_down_request,
    input [7:0] weight,

    output reg [2:0] current_floor,
    output reg [2:0] floor_display,

    output reg moving_up,
    output reg moving_down,

    output reg door_open,
    output reg bell,
    output reg door_led,

    input emergency,
    input obstruction,
    input fire_alarm,
    input door_hold,
    input maintenance_mode,

    output reg alarm,

    output reg served,
    output reg [2:0] served_floor,
    output reg served_up,
    output reg served_down

);


//--------------------------------------------------
// Parameters and Registers
//--------------------------------------------------

parameter IDLE        = 3'b000;
parameter MOVING_UP   = 3'b001;
parameter MOVING_DOWN = 3'b010;
parameter DOOR_OPEN   = 3'b011;
parameter DOOR_CLOSE  = 3'b100;

parameter MAX_WEIGHT = 8'd200;

reg [2:0] state;

reg [1:0] floor_timer;
reg [1:0] door_timer;

reg [2:0] next_target;

reg [7:0] car_queue;
reg [7:0] up_queue;
reg [7:0] down_queue;

reg [4:0] door_open_timer;
reg [4:0] idle_timer;

reg door_timeout;

wire overload;

reg direction;
reg served_sent;

integer i;

reg found;
reg [2:0] target;

assign overload = (weight >= MAX_WEIGHT);


//--------------------------------------------------
// Main Elevator Controller
//--------------------------------------------------

always @(posedge clk or posedge reset)
begin

    if(reset)
    begin

        current_floor <= 0;
        state         <= IDLE;

        floor_timer   <= 0;
        door_timer    <= 0;

        door_open     <= 0;
        door_led      <= 0;

        direction     <= 1;

        floor_display <= 0;

        car_queue     <= 8'b00000000;
        up_queue      <= 8'b00000000;
        down_queue    <= 8'b00000000;

        moving_up     <= 0;
        moving_down   <= 0;

        next_target   <= 0;

        alarm         <= 0;

        idle_timer    <= 0;

        bell          <= 0;

        door_open_timer <= 0;
        door_timeout    <= 0;

        served       <= 0;
        served_floor <= 0;
        served_up    <= 0;
        served_down  <= 0;

        served_sent <= 0;

    end

    else
    begin

        //--------------------------------------------------
        // Alarm Logic
        //--------------------------------------------------

        if(emergency || overload || fire_alarm || door_timeout)
            alarm <= 1;
        else
            alarm <= 0;


        //--------------------------------------------------
        // Fire Alarm
        //--------------------------------------------------

        if(fire_alarm)
        begin

            moving_up   <= 0;
            moving_down <= 0;

            floor_timer <= 0;
            door_timer  <= 0;

            if(current_floor > 0)
            begin
                current_floor <= current_floor - 1;
            end

            else
            begin

                state     <= DOOR_OPEN;
                door_open <= 1;

            end

        end


        //--------------------------------------------------
        // Maintenance Mode
        //--------------------------------------------------

        else if(maintenance_mode)
        begin

            moving_up   <= 0;
            moving_down <= 0;

        end


        //--------------------------------------------------
        // Emergency
        //--------------------------------------------------

        else if(emergency)
        begin

            state       <= DOOR_OPEN;
            door_open   <= 1;

            moving_up   <= 0;
            moving_down <= 0;

            floor_timer <= 0;
            door_timer  <= 0;

        end


        //--------------------------------------------------
        // Normal Operation
        //--------------------------------------------------

        else
        begin

            if(door_open)
                door_led <= 1;
            else
                door_led <= 0;

            floor_display <= current_floor;

            car_queue  <= car_queue  | floor_request;
            up_queue   <= up_queue   | hall_up_request;
            down_queue <= down_queue | hall_down_request;

            served       <= 0;
            served_up    <= 0;
            served_down  <= 0;
            served_floor <= 0;


            //--------------------------------------------------
            // FSM
            //--------------------------------------------------

            case(state)


                //--------------------------------------------------
                // IDLE
                //--------------------------------------------------

                IDLE:
                begin

                    if(overload)
                    begin

                        state     <= DOOR_OPEN;
                        door_open <= 1;

                    end

                    else
                    begin

                        moving_up   <= 0;
                        moving_down <= 0;

                        found  = 0;
                        target = next_target;


                        //--------------------------------------------------
                        // If we have not yet reached the current target,
                        // keep moving toward it.
                        //--------------------------------------------------

                        if(current_floor != next_target)
                        begin

                            found = 1;
                            target = next_target;

                        end


                        //--------------------------------------------------
                        // Otherwise search for a new target
                        //--------------------------------------------------

                        else
                        begin

                            target = current_floor;


                            if(direction)
                            begin

                                //--------------------------------------------------
                                // Search upward
                                //--------------------------------------------------

                                for(i = current_floor + 1; i < 8; i = i + 1)
                                begin

                                    if(!found &&
                                       (car_queue[i] ||
                                        up_queue[i] ||
                                        down_queue[i]))
                                    begin

                                        target = i;
                                        found = 1;

                                    end

                                end


                                //--------------------------------------------------
                                // Nothing above -> search below
                                //--------------------------------------------------

                                if(!found)
                                begin

                                    for(i = current_floor - 1; i >= 0; i = i - 1)
                                    begin

                                        if(!found &&
                                           (car_queue[i] ||
                                            down_queue[i] ||
                                            up_queue[i]))
                                        begin

                                            target = i;
                                            found = 1;

                                        end

                                    end

                                end

                            end


                            else
                            begin

                                //--------------------------------------------------
                                // Search downward
                                //--------------------------------------------------

                                for(i = current_floor - 1; i >= 0; i = i - 1)
                                begin

                                    if(!found &&
                                       (car_queue[i] ||
                                        down_queue[i] ||
                                        up_queue[i]))
                                    begin

                                        target = i;
                                        found = 1;

                                    end

                                end


                                //--------------------------------------------------
                                // Nothing below -> search above
                                //--------------------------------------------------

                                if(!found)
                                begin

                                    for(i = current_floor + 1; i < 8; i = i + 1)
                                    begin

                                        if(!found &&
                                           (car_queue[i] ||
                                            up_queue[i] ||
                                            down_queue[i]))
                                        begin

                                            target = i;
                                            found = 1;

                                        end

                                    end

                                end

                            end

                        end


                        //--------------------------------------------------
                        // Update target and direction
                        //--------------------------------------------------

                        next_target <= target;

                        if(found)
                        begin

                            if(target > current_floor)
                                direction <= 1;
                            else if(target < current_floor)
                                direction <= 0;


                            if(target > current_floor)
                                state <= MOVING_UP;
                            else if(target < current_floor)
                                state <= MOVING_DOWN;

                        end

                    end

                end


                //--------------------------------------------------
                // MOVING UP
                //--------------------------------------------------

                MOVING_UP:
                begin

                    moving_up   <= 1;
                    moving_down <= 0;

                    direction <= 1;

                    floor_timer <= floor_timer + 1;


                    if(floor_timer == 2)
                    begin

                        floor_timer <= 0;

                        current_floor <= current_floor + 1;


                        //--------------------------------------------------
                        // Have we reached the target?
                        //--------------------------------------------------

                        if(current_floor + 1 == next_target)
                        begin

                            moving_up <= 0;
                            state <= DOOR_OPEN;
                            door_open <= 1;

                        end

                        else
                        begin

                            state <= MOVING_UP;

                        end

                    end

                end


                //--------------------------------------------------
                // MOVING DOWN
                //--------------------------------------------------

                MOVING_DOWN:
                begin

                    moving_up   <= 0;
                    moving_down <= 1;

                    direction <= 0;

                    floor_timer <= floor_timer + 1;


                    if(floor_timer == 2)
                    begin

                        floor_timer <= 0;

                        current_floor <= current_floor - 1;


                        //--------------------------------------------------
                        // Have we reached the target?
                        //--------------------------------------------------

                        if(current_floor - 1 == next_target)
                        begin

                            moving_down <= 0;
                            state <= DOOR_OPEN;
                            door_open <= 1;

                        end

                        else
                        begin

                            state <= MOVING_DOWN;

                        end

                    end

                end


                //--------------------------------------------------
                // DOOR OPEN
                //--------------------------------------------------

                DOOR_OPEN:
                begin

                    door_open <= 1;


                    if(door_timer == 0)
                        bell <= 1;
                    else
                        bell <= 0;


                    //--------------------------------------------------
                    // Send served signal only once
                    //--------------------------------------------------

                    if(!served_sent)
                    begin

                        served <= 1;
                        served_floor <= current_floor;

                        served_up   <= up_queue[current_floor];
                        served_down <= down_queue[current_floor];

                        served_sent <= 1;

                    end


                    //--------------------------------------------------
                    // Clear requests at current floor
                    //--------------------------------------------------

                    car_queue[current_floor]  <= 0;
                    up_queue[current_floor]   <= 0;
                    down_queue[current_floor] <= 0;


                    //--------------------------------------------------
                    // Door hold
                    //--------------------------------------------------

                    if(door_hold)
                    begin

                        door_timer <= 0;

                    end

                    else
                    begin

                        door_timer <= door_timer + 1;


                        if(door_timer == 2)
                        begin

                            state      <= DOOR_CLOSE;
                            door_timer <= 0;

                        end

                    end


                    //--------------------------------------------------
                    // Door timeout
                    //--------------------------------------------------

                    if(door_open_timer < 20)
                        door_open_timer <= door_open_timer + 1;

                    if(door_open_timer >= 20)
                        door_timeout <= 1;
                    else
                        door_timeout <= 0;

                end


                //--------------------------------------------------
                // DOOR CLOSE
                //--------------------------------------------------

                DOOR_CLOSE:
                begin

                    door_open_timer <= 0;
                    served_sent <= 0;


                    if(obstruction)
                    begin

                        state      <= DOOR_OPEN;
                        door_open  <= 1;
                        door_timer <= 0;

                    end

                    else
                    begin

                        door_open <= 0;

                        door_timer <= door_timer + 1;


                        if(door_timer == 2)
                        begin

                            state      <= IDLE;
                            door_timer <= 0;

                        end

                    end

                end

            endcase

        end

    end

end

endmodule
