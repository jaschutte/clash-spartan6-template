{
  description = "A template for using Clash with a Spartan 6 FPGA";
  outputs = { self }: {
    templates.default = {
      path = ./template;
      description = "A template for using Clash with a Spartan 6 FPGA";
    };
  };
}
