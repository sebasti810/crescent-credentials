pragma circom 2.1.6;

// Timing-channel gadget ("weighted padding", thermometer style).
//
// We get a number s (this is secret value * weight) and make N wires. The
// first s wires we set to 1, the rest stay 0. The Groth16 prover skips the
// zero wires in its MSM, so the proving time grows together with s. Like this
// the secret can be read out from the timing.
//
// We count the ones with a running sum (acc), one step at a time. This is much
// faster to compile than one big sum over all N wires at once. acc[N] === s
// forces exactly s ones, so the prover can not cheat. Also s must be <= N,
// otherwise it can not hold and the proof fails (so it is also a range check).
template Thermometer(N) {
    signal input s;
    signal pwire[N];
    signal acc[N + 1];

    acc[0] <== 0;
    for (var i = 0; i < N; i++) {
        pwire[i] <-- (i < s) ? 1 : 0;     // hint: fill the first s wires with 1
        pwire[i] * (pwire[i] - 1) === 0;  // w must be 0 or 1
        acc[i + 1] <== acc[i] + pwire[i]; // running sum, add one wire per step
    }
    acc[N] === s; // exactly s wires are 1
}
