final: prev: {
  web-eid-app = prev.web-eid-app.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      header="lib/libelectronic-id/lib/libpcsc-cpp/include/pcsc-cpp/pcsc-cpp.hpp"
      if ! grep -q '<cstdint>' "$header"; then
        if grep -q '^#pragma once' "$header"; then
          sed -i 's/^#pragma once/#pragma once\n#include <cstdint>/' "$header"
        elif grep -q '^#include ' "$header"; then
          sed -i '0,/^#include /s//&\n#include <cstdint>/' "$header"
        else
          sed -i '1i #include <cstdint>' "$header"
        fi
      fi
    '';
  });
}
