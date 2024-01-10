package moof

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

func (b Buffer) GetRune() rune {
	if b.Len() < 1 {
		return -1
	}
	return b.s[b.i]
}

func (b Buffer) GetString(l int) string {
	return string(b.s[b.i:min(len(b.s), b.i + l)])
}

func (b Buffer) Len() int {
	return len(b.s) - b.i
}

func (b *Buffer) Consume(l int) bool {
	if b.Len() < l {
		return false
	}
	b.i += l
	return true
}

func (b *Buffer) ConsumeString(s string) bool {
	if b.GetString(len(s)) != s {
		return false
	}
	return b.Consume(len(s))
}

func (b *Buffer) ConsumeOneOf(chars string) bool {
	if b.Len() < 1 {
		return false
	}
	r := b.GetRune()
	for _, char := range chars {
		if r == char {
			b.Consume(1)
			return true
		}
	}
	return false
}

func (b *Buffer) ConsumeOneOrMoreOf(chars string) bool {
	if !b.ConsumeOneOf(chars) {
		return false
	}
	for b.ConsumeOneOf(chars) {}
	return true
}
