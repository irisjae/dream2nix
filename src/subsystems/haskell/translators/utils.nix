{
  lib,
  pkgs,
}: let
  l = lib // builtins;

  all-cabal-json = let
    src = pkgs.fetchurl {
      url = "https://github.com/nix-community/all-cabal-json/tarball/bdb5c96a57926392fbfd567867fada983f480195";
      sha256 = "sha256-C6/4T4yJ8uT0qmRezY5YT+dl0v6/FTpMEahuBMnPhiU=";
    };
  in
    pkgs.runCommandLocal "all-cabal-json" {} ''
      mkdir $out
      cd $out
      tar --strip-components 1 -xf ${src}
    '';

  findJsonFromCabalCandidate = name: version: let
    jsonCabalFile = "${all-cabal-json}/${name}/${version}/${name}.json";
  in
    if (! (l.pathExists jsonCabalFile))
    then throw ''"all-cabal-json" seems to be outdated''
    else l.fromJSON (l.readFile jsonCabalFile);
in {
  inherit findJsonFromCabalCandidate;

  findSha256FromCabalCandidate = name: version: let
    hashFile = "${all-cabal-json}/${name}/${version}/${name}.hashes.json";
  in
    if (! (l.pathExists hashFile))
    then throw ''"all-cabal-json" seems to be outdated''
    else (l.fromJSON (l.readFile hashFile)).package-hashes.SHA256;

  /*
  Convert all cabal files for a given list of candidates to an attrset.
  access like: ${name}.${version}.${some_cabal_attr}
  */
  batchFindJsonFromCabalCandidates = candidates: (l.pipe candidates
    [
      (l.map ({
        name,
        version,
      }: {"${name}" = version;}))
      l.zipAttrs
      (l.mapAttrs (
        name: versions:
          l.genAttrs versions (findJsonFromCabalCandidate name)
      ))
    ]);

  getHackageUrl = {
    name,
    version,
    ...
  }: "https://hackage.haskell.org/package/${name}-${version}.tar.gz";
}