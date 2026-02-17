// Learned about .vh files for macros so that multiple files like song_reader
// and song_reader_tb can use the same macros without having to copy and paste
// their definitions

`ifndef MY_MACROS_VH
`define MY_MACROS_VH

// States are one-hot encoded
`define STATE_WIDTH 5 //number of states
`define IDLE_STATE               5'b10000
`define LOAD_NOTE_STATE          5'b01000
`define PLAY_NOTE_STATE          5'b00100
`define WAIT_FOR_NOTE_DONE_STATE 5'b00010
`define INCREMENT_STATE          5'b00001


`endif

