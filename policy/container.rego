package projeto.container

import rego.v1

default allow := false

# O projeto exige UID numérico, positivo, com GID opcional numérico.
allow if {
    regex.match(`^[1-9][0-9]*(:[0-9]+)?$`, object.get(input, "user", ""))
}
