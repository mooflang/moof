package moof_test

import (
	"testing"

	"github.com/mooflang/moof"
	"github.com/stretchr/testify/require"
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

func TestBuffer(t *testing.T) {
	buf := moof.NewBuffer("foobar")
	require.Equal(t, "foo", buf.GetString(3))
	require.True(t, buf.ConsumeString("foo"))
	require.False(t, buf.ConsumeString("foo"))
	require.Equal(t, 'b', buf.GetRune())
	require.True(t, buf.ConsumeOneOf("dib"))
	require.False(t, buf.ConsumeOneOf("dib"))

	buf2 := buf.Duplicate()
	require.Equal(t, "ar", buf.GetString(2))
	require.Equal(t, "ar", buf2.GetString(2))
	require.True(t, buf.ConsumeOneOf("abcd"))
	require.Equal(t, "r", buf.GetString(2))
	require.Equal(t, "ar", buf2.GetString(2))

	buf3 := moof.NewBuffer("abcd1234")
	require.True(t, buf3.ConsumeOneOrMoreOf("abxyz"))
	require.False(t, buf3.ConsumeOneOrMoreOf("abxyz"))
	require.Equal(t, "cd1234", buf3.GetString(6))
	require.True(t, buf3.ConsumeOneOrMoreOf("4321dc"))
	require.Equal(t, 0, buf3.Len())
}
