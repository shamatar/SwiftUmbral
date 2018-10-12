# Description

Native pure Swift library for Umbral proxy re-encryption protocol. Based on the original [paper](https://github.com/nucypher/umbral-doc/blob/master/umbral-doc.pdf).

## Installation

Add the following line to your Podfile

```
  pod 'SwiftUmbral', '~> 0.5'
```

## Functions and limitations

- Based on EllipticSwift library and uses precompiled curves from there (secp256k1 and Ethereum's BN256)
- No proof of re-encryption is implemented yet
- Performance in Debug mode is sometimes unpredictable, but it's on par with C implementations when built for Release
- No serialization implemented yet

## Authors

- Alex Vlasov, [shamatar](https://github.com/shamatar), alex.m.vlasov@gmail.com