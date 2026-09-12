{ lib, ... }:
{
  options.omanix.hardware.isLaptop = lib.mkOption {
    type = lib.types.nullOr lib.types.bool;
    default = null;
    example = true;
    description = ''
      Override laptop auto-detection for omanix-hw-laptop. null (the default)
      lets the runtime probe decide (ACPI lid switch / DMI chassis type); true
      or false forces the answer for hosts the probe reads wrong. Consumed by
      the home-manager scripts module, which bakes it into the script as
      OMANIX_IS_LAPTOP.
    '';
  };
}
