let Module = ./Module.dhall

in      Module.make Module.Mode.ASCII
    /\  { Unicode = Module.make Module.Mode.Unicode }
