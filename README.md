<a id="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![project_license][license-shield]][license-url]

<br />

<h3 align="center">Selene</h3>

  <p align="center">
    Selene, a lightweight WebAssembly JIT runtime written in Zig.
    <br />
    <a href="https://github.com/acctress/selene"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/acctress/selene/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/acctress/selene/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

> ⚠️ Selene is early and incomplete. Currently supports a subset of Wasm - enough to run arithmetic, control flow, and function calls.

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

Selene is a lightweight WebAssembly JIT runtime written in Zig. It parses `.wasm` binaries, translates them into zjit's SSA IR, and compiles them to native machine code at runtime. Built entirely from scratch, no LLVM, no Cranelift, no depedencies.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [![Zig][Zig]][Zig-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Example
```bash
$ selene inspect add.wasm
functions (1):
  add : (i32, i32) -> i32
$ selene run add.wasm --fn add -- 10 20
30
```


<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Commands
```
selene run <file.wasm>                              # run default export
selene run <file.wasm> --fn <fn_name>               # call a specific exported function
selene run <file.wasm> --fn <fn_name> -- 1 2 3      # pass arguments
selene inspect <file.wasm>                          # dump sections, exports, imports
selene inspect <file.wasm>  --functions             # list all functions and signatures
selene inspect <file.wasm>  --exports               # list exports
```

#### Future flags
```
--verbose       # Log IR and show compilation steps
--interpret     # A fallback interpreter mode, no JIT
--dump-ir       # Log zjit IR before code generation
--dump-asm      # Log native ASM output 
```

### Prerequisites
* Zig 0.14.0 or later
* A `.wasm` binary

### Installation

#### Build from source
```bash
git clone https://github.com/acctress/selene.git
cd selene
zig build
```

```bash
./zig-out/bin/selene run file.wasm
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ROADMAP -->
## Roadmap

- [x] Wasm binary parser
    - [x] Magic number + version validation
    - [x] Section loop (type, func, code)
    - [x] LEB128 decoding
- [x] Wasm validator
- [ ] Wasm to zjit IR translator
    - [x] Arithmetic opcodes (i32.add, i32.sub)
    - [ ] Control flow (block, loop, if, br, br_if)
    - [x] Function calls
- [x] zjit JIT backend integration
- [x] Native code execution
- [ ] Host + sandbox
    - [ ] Linear memory
    - [ ] Imports and exports
    - [ ] WASI support
- [ ] CLI
  - [x] `run` subcommand
  - [x] `inspect` subcommand
  - [ ] `--dump-ir` flag
  - [ ] `--dump-asm` flag
  - [ ] `--interpret` fallback
- [ ] Optimisation passes
  - [ ] Pass manager
  - [ ] Constant folding
  - [ ] DCE
  - [ ] Copy propagation
  
See the [open issues](https://github.com/acctress/selene/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[//]: # (### Top contributors:)

[//]: # ()
[//]: # (<a href="https://github.com/acctress/selene/graphs/contributors">)

[//]: # (  <img src="https://contrib.rocks/image?repo=acctress/selene" alt="contrib.rocks image" />)

[//]: # (</a>)



<!-- LICENSE -->
## License

Distributed under the MIT license. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Discord - `acctress`
Email - `0x2014@proton.me`

Project Link: [https://github.com/acctress/selene](https://github.com/acctress/selene)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/acctress/selene.svg?style=for-the-badge
[contributors-url]: https://github.com/acctress/selene/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/acctress/selene.svg?style=for-the-badge
[forks-url]: https://github.com/acctress/selene/network/members
[stars-shield]: https://img.shields.io/github/stars/acctress/selene.svg?style=for-the-badge
[stars-url]: https://github.com/acctress/selene/stargazers
[issues-shield]: https://img.shields.io/github/issues/acctress/selene.svg?style=for-the-badge
[issues-url]: https://github.com/acctress/selene/issues
[license-shield]: https://img.shields.io/github/license/acctress/selene.svg?style=for-the-badge
[license-url]: https://github.com/acctress/selene/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png
<!-- Shields.io badges. You can a comprehensive list with many more badges at: https://github.com/inttter/md-badges -->
[Zig]: https://img.shields.io/badge/zig-000000?style=for-the-badge&logo=zig&logoColor=white
[Zig-url]: https://ziglang.org/