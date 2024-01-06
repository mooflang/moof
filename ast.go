package moof

import (
	"bytes"
)

type NodeType int
const (
	For NodeType = iota
)

type Node struct {
	Type NodeType
	Content []byte
}

type AST struct {
	Raw []*Node
}

func Parse(data []byte) *AST {
	return nil
}

var tFor = newStringToken("for", For)

type token interface {
	match([]byte) (*AST, int, error)
}

type tokenEmbed struct {
	next []*token
}

func (te *tokenEmbed) addNext(t *token) {
	te.next = append(te.next, t)
}

type stringToken struct {
	tokenEmbed
	b []byte
	typ NodeType
}

func newStringToken(str string, typ NodeType) *stringToken {
	return &stringToken{
		b: []byte(str),
		typ: typ,
	}
}

func (st stringToken) match(b []byte, typ NodeType) *Node {
	if !bytes.HasPrefix(b, st.b) {
		return nil
	}

	return &Node{
		Type: st.typ,
		Content: st.b,
	}
}
