use ark_bn254::{Bn254, Fr};
use ark_crypto_primitives::snark::SNARK;
use ark_groth16::Groth16;
use ark_relations::{
    lc,
    r1cs::{ConstraintSynthesizer, ConstraintSystemRef, SynthesisError},
};
use ark_std::rand::{rngs, SeedableRng};
use std::{env, time::Instant};

#[derive(Clone, Copy)]
struct Thermometer {
    s: u64,   // number of wires to light up (= secret * padding)
    n: usize, // total wires, must be >= s
}

impl ConstraintSynthesizer<Fr> for Thermometer {
    fn generate_constraints(self, cs: ConstraintSystemRef<Fr>) -> Result<(), SynthesisError> {
        for i in 0..self.n {
            let bit = if (i as u64) < self.s {
                Fr::from(1u64)
            } else {
                Fr::from(0u64)
            };
            let w = cs.new_witness_variable(|| Ok(bit))?;
            // w must be 0 or 1, we force this with w*w = w
            cs.enforce_constraint(lc!() + w, lc!() + w, lc!() + w)?;
        }
        Ok(())
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let n: usize = args
        .get(1)
        .and_then(|x| x.parse().ok())
        .unwrap_or(1_000_000);
    let reps: usize = args.get(2).and_then(|x| x.parse().ok()).unwrap_or(5);
    let svals: Vec<u64> = if args.len() > 3 {
        args[3..]
            .iter()
            .map(|x| x.parse().expect("S values must be integers"))
            .collect()
    } else {
        // some default values to check if no s-val is provided
        vec![
            0,
            (n / 4) as u64,
            (n / 2) as u64,
            (3 * n / 4) as u64,
            n as u64,
        ]
    };

    let mut rng = rngs::StdRng::seed_from_u64(0);
    eprintln!("N={n}  reps={reps}  sweep={svals:?}");
    eprintln!("Groth16 setup runs only one time (just the structure, it depends on N not on S)...");
    let t0 = Instant::now();
    let (pk, _vk) =
        Groth16::<Bn254>::circuit_specific_setup(Thermometer { s: 0, n }, &mut rng).unwrap();
    eprintln!("setup finished in {:.1}s\n", t0.elapsed().as_secs_f64());

    for &s in &svals {
        for _ in 0..reps {
            let t = Instant::now();
            let _proof = Groth16::<Bn254>::create_proof_with_reduction(
                Thermometer { s, n },
                &pk,
                Fr::from(0u64),
                Fr::from(0u64),
            )
            .unwrap();
            let ms = t.elapsed().as_secs_f64() * 1000.0;
            println!("S={s} prove_ms={ms:.1}");
        }
    }
}
