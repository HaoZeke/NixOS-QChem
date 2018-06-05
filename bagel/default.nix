{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, python, boost, openmpi, libxc, fetchpatch, openblas
, scalapack, makeWrapper, openssh
} :

let
  version = "1.1.1";

in stdenv.mkDerivation {
  name = "bagel-${version}";

  src = fetchFromGitHub {
    owner = "nubakery";
    repo = "bagel";
    rev = "v${version}";
    sha256 = "1yxkhqd9rng02g3zd7c1b32ish1b0gkrvfij58v5qrd8yaiy6pyy";
  };

  nativeBuildInputs = [ autoconf automake libtool openssh ];
  buildInputs = [ python boost libxc openblas scalapack openmpi ];

  CXXFLAGS="-DNDEBUG -O3 -mavx -lopenblas";

#  configureFlags = [ "--disable-scalapack" "--with-mpi" "--disable-smith" "--with-libxc" ];
  configureFlags = [ "--with-libxc" "--with-mpi=openmpi" ];

  postPatch = ''
    # Fixed upstream
    sed -i '/using namespace std;/i\#include <string.h>' src/util/math/algo.cc
  '';

  preConfigure = ''
    ./autogen.sh
  '';

  enableParallelBuilding = true;

  postInstall = ''
    cat << EOF > $out/bin/bagel
    if [ $# -lt 1 ]; then
    echo
    echo "Usage: `basename $0` [mpirun parameters] <input file>"
    echo
    exit
    fi
    ${openmpi}/bin/mpirun ''${@:1:$#-1} $out/bin/BAGEL ''${@:$#}
    EOF 
    chmod +x $out/bin/bagel
  '';

  installCheckPhase = ''
    echo "Running HF test"
    export OMP_NUM_THREADS=1
    mpirun -np 1 $out/bin/BAGEL test/hf_svp_hf.json > log
    echo "Check output"
    grep "SCF iteration converged" log
    grep "99.847790" log
  '';

  doInstallCheck = true;

  meta = with stdenv.lib; {
    description = "Brilliantly Advanced General Electronic-structure Library";
    homepage = http://www.shiozaki.northwestern.edu/bagel.php;
    license = with licenses; gpl3;
    platforms = platforms.linux;
  };
}

