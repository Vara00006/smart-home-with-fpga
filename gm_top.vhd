
module gm_top(input ir_pin,clk,rst,ir_pin2,echo,output servo,led,trig,servo_out,LED);
Main sani(ir_pin,clk,rst,servo);
ir_led_delay light(clk,ir_pin2,led);
fsm_controller door(clk,rst,echo,trig,servo_out,LED);
endmodule
