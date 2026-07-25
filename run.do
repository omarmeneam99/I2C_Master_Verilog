vlib work
vlog  I2C_master_tb.v I2C_master_tb.v
vsim -voptargs=+acc work.I2C_master_tb
add wave *
add wave -position insertpoint  \
sim:/I2C_master_tb/DUT/bit_cnt \
sim:/I2C_master_tb/DUT/addr_byte \
sim:/I2C_master_tb/DUT/cs \
sim:/I2C_master_tb/DUT/ns
run -all 
#quit -sim