module ultrasonic(clk, start, trigger, echo, distance_raw, new_measure, timeout);

	input clk, start, echo;
	output trigger, new_measure, timeout;
	output reg [20:0] distance_raw;

	parameter 	CLK_MHZ = 50,			// fréquence horloge en MHz
			TRIGGER_PULSE_US = 12,  	// durée impulsion trigger en microsecondes
			TIMEOUT_MS = 25;		// timeout en millisecondes
	
	localparam	COUNT_TRIGGER_PULSE = CLK_MHZ * TRIGGER_PULSE_US;
	localparam  	COUNT_TIMEOUT = CLK_MHZ * TIMEOUT_MS * 1000;

	reg [20:0] counter;
	
	reg[2:0]  state, state_next;
	localparam 	IDLE 		= 0,
			TRIG 		= 1,
			WAIT_ECHO_UP 	= 2,
			MEASUREMENT 	= 3,
			MEASURE_OK 	= 4;
	
	always @(posedge clk) state <= state_next;
	
	wire measurement;
	assign measurement = (state == MEASUREMENT);
	
	assign new_measure = (state == MEASURE_OK);
	
	wire counter_timeout;
	assign counter_timeout = (counter >= COUNT_TIMEOUT);
	
	assign timeout = new_measure && counter_timeout;
	assign trigger = (state == TRIG);
	
	wire enable_counter;
	assign enable_counter = trigger || echo;	
	
	always @(posedge clk) begin
		if (enable_counter)
			counter <=  counter + 21'b1;
		else
			counter <= 21'b0;  
	end	
	
	always @(posedge clk) begin
		if (enable_counter && measurement)
			distance_raw <= counter;
	end
	
	always @(*) begin
		state_next <= state; // par défaut, l'état est maintenu

		case (state)
			IDLE: begin // signal trigger sur impulsion start
				if (start) state_next <= TRIG;
			end
			
			TRIG: begin // durée signal trig > 10us pour SRF05
				if (counter >= COUNT_TRIGGER_PULSE) state_next <= WAIT_ECHO_UP;
			end
			
			WAIT_ECHO_UP: begin
				// avec le SRF05, il y a un délai de 750us après le trig avant que le
				// signal echo bascule à l'état haut.
				if (echo) state_next <= MEASUREMENT;
			end
			
			MEASUREMENT: begin // attente echo qui redescend, ou timeout
				if (counter_timeout || (~echo)) state_next <= MEASURE_OK;
			end
			
			MEASURE_OK: begin
				state_next <= IDLE;			
			end

			default: begin
				state_next <= IDLE;
			end	
		endcase
		
	end
					
	
endmodule
module Ultrasonic_3(CLOCK_50, TRIG, ECHO,distance_raw);

	input 		 CLOCK_50;
	output 		 TRIG;
	input		 ECHO;  // /!\  Alim. du capteur 5V, abaisser le signal ECHO à 3v3 (diviseur tension)
	output wire [20:0] distance_raw;
	
	wire start, new_measure, timeout;
	

	reg [24:0] counter_ping;
	
	localparam CLK_MHZ = 50;	 // horloge 50MHz
	localparam PERIOD_PING_MS = 60;  // période des ping en ms
	
	localparam COUNTER_MAX_PING = CLK_MHZ * PERIOD_PING_MS * 1000;

	// avec horloge 50MHz et c=345m/s, distance_raw = 2900 * D(cm)



	ultrasonic #(	.CLK_MHZ(50), 
			.TRIGGER_PULSE_US(12), 
			.TIMEOUT_MS(3)
					) U1
						(	.clk(CLOCK_50),
							.trigger(TRIG),
							.echo(ECHO),
							.start(start),
							.new_measure(new_measure),
							.timeout(timeout),
							.distance_raw(distance_raw)
						);
		
		// avec timeout=3ms => distance > 52cm						

	assign start = (counter_ping == COUNTER_MAX_PING - 1);

	always @(posedge CLOCK_50) begin
		if (counter_ping == COUNTER_MAX_PING - 1)
			counter_ping <= 25'd0;
		else begin	
			counter_ping <= counter_ping + 25'd1;
		end
	end


endmodule
