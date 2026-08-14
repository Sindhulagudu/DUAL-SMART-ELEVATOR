module dispatcher(

    input clk,
    input reset,

    input [2:0] elevator1_floor,
    input [2:0] elevator2_floor,

    input elevator1_busy,
    input elevator2_busy,

    input elevator1_up,
    input elevator1_down,

    input elevator2_up,
    input elevator2_down,

    input [7:0] hall_up_request,
    input [7:0] hall_down_request,

    input elevator1_served,
    input [2:0] elevator1_served_floor,
    input elevator1_served_up,
    input elevator1_served_down,

    input elevator2_served,
    input [2:0] elevator2_served_floor,
    input elevator2_served_up,
    input elevator2_served_down,

    output reg [7:0] hall_up_to_e1,
    output reg [7:0] hall_up_to_e2,

    output reg [7:0] hall_down_to_e1,
    output reg [7:0] hall_down_to_e2

);

//--------------------------------------------------
// Registers
//--------------------------------------------------

integer i;

reg [7:0] up_pending;
reg [7:0] down_pending;

reg [7:0] up_assigned;
reg [7:0] down_assigned;

reg [7:0] next_up_pending;
reg [7:0] next_down_pending;

reg [7:0] next_up_assigned;
reg [7:0] next_down_assigned;

reg [2:0] request_floor;

reg request_is_up;

reg found;

reg [2:0] distance1;
reg [2:0] distance2;


//--------------------------------------------------
// Pending Queue Management
//--------------------------------------------------

always @(posedge clk or posedge reset)
begin

    if(reset)
    begin

        up_pending   <= 8'b0;
        down_pending <= 8'b0;

        up_assigned   <= 8'b0;
        down_assigned <= 8'b0;

    end

    else
    begin

        //------------------------------------------
        // Store new hall requests
        //------------------------------------------

        next_up_pending   = up_pending   | hall_up_request;
        next_down_pending = down_pending | hall_down_request;

        next_up_assigned   = up_assigned;
        next_down_assigned = down_assigned;


        //------------------------------------------
        // Clear served UP requests
        //------------------------------------------

        if(elevator1_served && elevator1_served_up)
        begin
            next_up_pending[elevator1_served_floor] = 1'b0;
            next_up_assigned[elevator1_served_floor] = 1'b0;
        end

        if(elevator2_served && elevator2_served_up)
        begin
            next_up_pending[elevator2_served_floor] = 1'b0;
            next_up_assigned[elevator2_served_floor] = 1'b0;
        end


        //------------------------------------------
        // Clear served DOWN requests
        //------------------------------------------

        if(elevator1_served && elevator1_served_down)
        begin
            next_down_pending[elevator1_served_floor] = 1'b0;
            next_down_assigned[elevator1_served_floor] = 1'b0;
        end

        if(elevator2_served && elevator2_served_down)
        begin
            next_down_pending[elevator2_served_floor] = 1'b0;
            next_down_assigned[elevator2_served_floor] = 1'b0;
        end


        //------------------------------------------
        // Remember assigned requests
        //------------------------------------------

        if(hall_up_to_e1 != 8'b0)
            next_up_assigned = next_up_assigned | hall_up_to_e1;

        if(hall_up_to_e2 != 8'b0)
            next_up_assigned = next_up_assigned | hall_up_to_e2;

        if(hall_down_to_e1 != 8'b0)
            next_down_assigned = next_down_assigned | hall_down_to_e1;

        if(hall_down_to_e2 != 8'b0)
            next_down_assigned = next_down_assigned | hall_down_to_e2;


        up_pending    <= next_up_pending;
        down_pending  <= next_down_pending;

        up_assigned   <= next_up_assigned;
        down_assigned <= next_down_assigned;

    end

end


//--------------------------------------------------
// Dispatcher Decision Logic
//--------------------------------------------------

always @(*)
begin

    //------------------------------
    // Default outputs
    //------------------------------

    hall_up_to_e1   = 8'b0;
    hall_up_to_e2   = 8'b0;

    hall_down_to_e1 = 8'b0;
    hall_down_to_e2 = 8'b0;

    found = 0;
    request_is_up = 0;
    request_floor = 3'd0;


    //------------------------------
    // Search UP requests first
    //------------------------------

    for(i = 0; i < 8; i = i + 1)
    begin

        if(!found &&
           up_pending[i] &&
           !up_assigned[i])
        begin

            found = 1;
            request_is_up = 1;
            request_floor = i[2:0];

        end

    end


    //------------------------------
    // Search DOWN requests
    //------------------------------

    if(!found)
    begin

        for(i = 0; i < 8; i = i + 1)
        begin

            if(!found &&
               down_pending[i] &&
               !down_assigned[i])
            begin

                found = 1;
                request_is_up = 0;
                request_floor = i[2:0];

            end

        end

    end


    //--------------------------------------------------
    // Distance Calculation and Elevator Selection
    //--------------------------------------------------

    if(found)
    begin

        if(elevator1_floor >= request_floor)
            distance1 = elevator1_floor - request_floor;
        else
            distance1 = request_floor - elevator1_floor;

        if(elevator2_floor >= request_floor)
            distance2 = elevator2_floor - request_floor;
        else
            distance2 = request_floor - elevator2_floor;


        //--------------------------------------------------
        // UP REQUEST
        //--------------------------------------------------

        if(request_is_up)
        begin

            // Both elevators naturally passing this floor
            if(elevator1_up &&
               elevator1_floor <= request_floor &&
               elevator2_up &&
               elevator2_floor <= request_floor)
            begin

                if(distance1 <= distance2)
                    hall_up_to_e1[request_floor] = 1'b1;
                else
                    hall_up_to_e2[request_floor] = 1'b1;

            end


            // Elevator1 naturally passes
            else if(elevator1_up &&
                    elevator1_floor <= request_floor)
            begin

                hall_up_to_e1[request_floor] = 1'b1;

            end


            // Elevator2 naturally passes
            else if(elevator2_up &&
                    elevator2_floor <= request_floor)
            begin

                hall_up_to_e2[request_floor] = 1'b1;

            end


            // Both idle
            else if(!elevator1_busy &&
                    !elevator2_busy)
            begin

                if(distance1 <= distance2)
                    hall_up_to_e1[request_floor] = 1'b1;
                else
                    hall_up_to_e2[request_floor] = 1'b1;

            end


            // Elevator1 idle
            else if(!elevator1_busy)
            begin

                hall_up_to_e1[request_floor] = 1'b1;

            end


            // Elevator2 idle
            else if(!elevator2_busy)
            begin

                hall_up_to_e2[request_floor] = 1'b1;

            end


            // Otherwise...
            // Leave request pending.

        end


        //--------------------------------------------------
        // DOWN REQUEST
        //--------------------------------------------------

        else
        begin

            // Both elevators naturally passing this floor
            if(elevator1_down &&
               elevator1_floor >= request_floor &&
               elevator2_down &&
               elevator2_floor >= request_floor)
            begin

                if(distance1 <= distance2)
                    hall_down_to_e1[request_floor] = 1'b1;
                else
                    hall_down_to_e2[request_floor] = 1'b1;

            end


            // Elevator1 naturally passes
            else if(elevator1_down &&
                    elevator1_floor >= request_floor)
            begin

                hall_down_to_e1[request_floor] = 1'b1;

            end


            // Elevator2 naturally passes
            else if(elevator2_down &&
                    elevator2_floor >= request_floor)
            begin

                hall_down_to_e2[request_floor] = 1'b1;

            end


            // Both idle
            else if(!elevator1_busy &&
                    !elevator2_busy)
            begin

                if(distance1 <= distance2)
                    hall_down_to_e1[request_floor] = 1'b1;
                else
                    hall_down_to_e2[request_floor] = 1'b1;

            end


            // Elevator1 idle
            else if(!elevator1_busy)
            begin

                hall_down_to_e1[request_floor] = 1'b1;

            end


            // Elevator2 idle
            else if(!elevator2_busy)
            begin

                hall_down_to_e2[request_floor] = 1'b1;

            end


           

        end

    end

end

endmodule
