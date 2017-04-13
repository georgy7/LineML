#!/bin/bash

if [ "$COVERAGE" = true ]; then
    dub test --compiler=${DC} -b unittest-cov
    e=$?; if [[ $e != 0 ]]; then exit $e; fi
    dub fetch doveralls
    dub run doveralls --compiler=${DC}
else
    dub test --compiler=${DC}
    e=$?; if [[ $e != 0 ]]; then exit $e; fi
fi
