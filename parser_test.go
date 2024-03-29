package moof_test

import (
	"testing"

	"github.com/mooflang/moof"
	"github.com/stretchr/testify/require"
)

func TestParse(t *testing.T) {
	tree, err := moof.Parse(`
a = 1
b = 2
c = "foo\"bar"
d = c
e = b.+
f = b.+(1)
g = b.+(foo: 3)
b.foo(2)
b.foo() {}
b.foo() {%
	h = 5
%}
i = {}
b.bar(3, "foo")

Foo = $Class {%
	bar = $Int
	zig = 5
	foo = { (a: $Int, b: $String, c) -> d: $String
		bar.set(a)
		c.return(b)
	}
%}
`)
	require.NoError(t, err)

	t.Logf("\n%s", tree.Tree(""))
}

func TestBuffer(t *testing.T) {
	buf := moof.NewBuffer("foobar")
	require.Equal(t, "foo", buf.GetString(3))
	require.True(t, buf.ConsumeString("foo"))
	require.False(t, buf.ConsumeString("foo"))
	require.Equal(t, 'b', buf.GetRune())
	require.Equal(t, "b", buf.ConsumeOneOf("dib"))
	require.Equal(t, "", buf.ConsumeOneOf("dib"))

	buf2 := buf.Duplicate()
	require.Equal(t, "ar", buf.GetString(2))
	require.Equal(t, "ar", buf2.GetString(2))
	require.Equal(t, "a", buf.ConsumeOneOf("abcd"))
	require.Equal(t, "r", buf.GetString(2))
	require.Equal(t, "ar", buf2.GetString(2))

	buf3 := moof.NewBuffer("abcd1234")
	require.Equal(t, "ab", buf3.ConsumeManyOf("abxyz"))
	require.Equal(t, "", buf3.ConsumeManyOf("abxyz"))
	require.Equal(t, "cd1234", buf3.GetString(6))
	require.Equal(t, "cd1234", buf3.ConsumeManyOf("4321dc"))
	require.Equal(t, 0, buf3.Len())
}
