{ fetchFromGitLab, runCommand, mdbook }:
let
  src = fetchFromGitLab {
    protocol = "http";
    domain = "git.haganah.net";
    owner = "benj2468";
    repo = "bb-recipes";
    rev = "91831eb02f777551f526ecc00d42ad3091dc18fc";
    hash = "sha256-B2VJ+Rk46tLi8kAOFh+Wp7vUmZnqpT/zEV9847EA8D4=";
  };
in
runCommand "bb-recipes"
{
  nativeBuildInputs = [ mdbook ];
} ''
  mkdir $out

  cp -r ${src}/* ./

  mdbook build -d $out
''
