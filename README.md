
## image_filter_NEORV32: hardware accelerated image filter for NEORV32
The RISC-V processor NEORV32 is a wonderful project written by S. Nolting and many contributors that you can find at the link [NEORV32](https://github.com/stnolting/neorv32). This repository includes the custom hardware alongside a set of scripts to easily implement a hardware accelerated Image Filter for the processor inside the Vivado suite.  

Three solutions are presented: **full software**, **convoluter for CFU**  and a complete  **image filter inside CFS**. This solutions are created for squared images of resolution 32x32 to process using an isotropic filter.
***
### LICENSE
The code for the image filter is granted under the BSD-3 license. The NEORV32 processor, as submodule inside this repository, is also released under the BSD-3, all rights reserved to S.Nolting and project contributors.

