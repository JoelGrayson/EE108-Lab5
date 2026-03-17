# Development Notes
wave_display_og is for 1/4 of the screen, as used initially
wave_display is for the full screen
The ILAs are not necessary except for debugging and figuring out what is going on when initially creating this codebase.


**Integration Commands:**

`set_property CONTROL.TRIGGER_POSITION 30000 [get_hw_ilas hw_ila_2]` for the ILA to see the full signal. Otherwise, it is center-aligned by default like an oscilloscope, meaning it chops off the right part. This is an easier solution than just increasing the memory since I am worried of running out of BRAM. hw_ila_2 corresponds to the ila_1 in my case.



#### ILAs
* oscilloscope_ila (ila_0) - reads the raw ps2_clk and data signals coming from the keyboard
* key_code_ila (ila_1) - reads the keyboard code coming from the keyboard_signal_receiver and the keyboard note that is played (from keyboard_signal_rom)
    * keyboard_note, new_key, and key_code

