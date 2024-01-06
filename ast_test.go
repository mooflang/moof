package moof_test

import (
	"testing"

	"github.com/mooflang/moof"
)

func TestParse(t *testing.T) {
	moof.Parse([]byte(`
// All foo() instances run in parallel
for x in [y.foo() for y in z] {
}

// mix() pulls in next available value
a = [x.foo() for x in y]
b = [x.foo() for x in z]
for x in mix(a, b) {
	// Next value available from a or b until both complete
}

// {% %} blocks execute as parallel tasks
fn mix(streams: ...[%T]) [%T] {
	for stream in streams {%
		for item in stream {
			yield item
		}
	%}
	// We block here for all tasks to complete
}
`))
}
