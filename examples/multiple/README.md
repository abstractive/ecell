To run this example, you'll need 3 machines. Then:

- On machine A: `./start_piece.rb monitor IP_FOR_A IP_FOR_B`
- On machine B: `./run_process_and_children.sh IP_FOR_A IP_FOR_B`
- On machine C: `./start_piece.rb webstack IP_FOR_A IP_FOR_B`

You can see output in the `logs` directories on the various machines,
and machine C should start serving HTTP on 0.0.0.0:4567.

