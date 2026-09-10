{ ... }:
{
  flake.modules.homeManager."target.config.laptop" =
    { ... }:
    {
      services.ntfySubscriber = {
        enable = true;
        device = "laptop";
      };

      # Laptop-specific Home Manager overrides go here
    };
}
