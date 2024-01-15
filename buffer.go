package moof

import (
	"strings"
)

type Buffer struct {
	s []rune
	i int
}

func NewBuffer(s string) *Buffer {
	return &Buffer{
		s: []rune(s),
	}
}

func (b Buffer) Duplicate() *Buffer {
	return &Buffer{
		s: b.s,
		i: b.i,
	}
}

func (b Buffer) GetAll() string {
	return string(b.s[b.i:])
}

func (b Buffer) GetRune() rune {
	if b.Len() < 1 {
		return -1
	}
	return b.s[b.i]
}

func (b Buffer) GetString(l int) string {
	return string(b.s[b.i:min(len(b.s), b.i+l)])
}

func (b Buffer) Len() int {
	return len(b.s) - b.i
}

func (b Buffer) Pos() int {
	return b.i
}

func (b *Buffer) Consume(l int) bool {
	if b.Len() < l {
		return false
	}
	b.i += l
	return true
}

func (b *Buffer) MustConsume(l int) {
	if !b.Consume(l) {
		panic("MustConsume()")
	}
}

func (b *Buffer) ConsumeString(s string) bool {
	if b.GetString(len(s)) != s {
		return false
	}
	b.MustConsume(len(s))
	return true
}

func (b *Buffer) ConsumeOne() string {
	if b.Len() < 1 {
		return ""
	}
	r := b.GetRune()
	b.Consume(1)
	return string(r)
}

func (b *Buffer) ConsumeOneOf(chars string) string {
	if b.Len() < 1 {
		return ""
	}
	r := b.GetRune()
	for _, char := range chars {
		if r == char {
			b.Consume(1)
			return string(r)
		}
	}
	return ""
}

func (b *Buffer) ConsumeOneNotOf(chars string) string {
	if b.Len() < 1 {
		return ""
	}
	r := b.GetRune()
	for _, char := range chars {
		if r == char {
			return ""
		}
	}
	b.Consume(1)
	return string(r)
}

func (b *Buffer) ConsumeManyOf(chars string) string {
	s := []string{}
	for {
		c := b.ConsumeOneOf(chars)
		if c == "" {
			break
		}
		s = append(s, c)
	}
	return strings.Join(s, "")
}

func (b *Buffer) ConsumeManyNotOf(chars string) string {
	s := []string{}
	for {
		c := b.ConsumeOneNotOf(chars)
		if c == "" {
			break
		}
		s = append(s, c)
	}
	return strings.Join(s, "")
}
