pragma circom 2.1.6;

// Timing-channel gadget (weighted padding, thermometer style).
// We get a number s (= secret * weight) and set the first s of N wires to 1,
// the rest stay 0. The Groth16 prover skips the zero wires in its MSM, so the
// proving time grows with s. Like this the secret leaks over the timing.
template Thermometer(N) {
    signal input s;
    signal pwire[N];
    for (var i = 0; i < N; i++) {
        pwire[i] <-- (i < s) ? 1 : 0;     // hint: fill the first s wires with 1
        pwire[i] * (pwire[i] - 1) === 0;  // w must be 0 or 1
    }
}
