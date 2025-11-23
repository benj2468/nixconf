{
  default = _final: prev: {
    ctypesgen = prev.python3Packages.callPackage ./ctypesgen { };

    bb-recipes = prev.callPackage ./bb-recipes { };
  };
}
