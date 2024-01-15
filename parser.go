package moof

import (
	"fmt"
)

const base10Chars = "0123456789"

const whitespaceChars = " \t\n"

const reservedChars = whitespaceChars + "\".(){}%&="
const reservedFirstChars = reservedChars + base10Chars

type Parser struct {
	Err string
	Pos int
}

type NodeAssignment struct {
	LHS        *NodeLHS
	Expression *NodeExpression
}

type NodeExpression struct {
	// One of
	IntLiteral    *NodeIntLiteral
	StringLiteral *NodeStringLiteral
	SymbolName    *NodeSymbolName
}

type NodeIntLiteral struct {
	Value int64
}

type NodeLHS struct {
	// One of
	SymbolName *NodeSymbolName
}

type NodeRoot struct {
	Statements []*NodeStatement
}

type NodeStatement struct {
	// One of
	Assignment *NodeAssignment
}

type NodeStringLiteral struct {
	Value string
}

type NodeSymbolName struct {
	Value string
}

func Parse(s string) (*NodeRoot, error) {
	p := &Parser{}
	b := NewBuffer(s)

	n := p.ParseRoot(b)
	if n == nil {
		return nil, fmt.Errorf("pos=%d: %s", p.Pos, p.Err)
	}

	return n, nil
}

func (p *Parser) Error(b *Buffer, err string) {
	if b.Pos() < p.Pos {
		return
	}
	p.Err = err
	p.Pos = b.Pos()

}

func (p *Parser) ConsumeWhitespace(b *Buffer) {
	b.ConsumeManyOf(whitespaceChars)
}

func (p *Parser) ParseAssignment(b *Buffer) *NodeAssignment {
	n := &NodeAssignment{}

	n.LHS = p.ParseLHS(b)
	if n.LHS == nil {
		return nil
	}

	p.ConsumeWhitespace(b)

	if !b.ConsumeString("=") {
		p.Error(b, "missing: =")
		return nil
	}

	n.Expression = p.ParseExpression(b)
	if n.Expression == nil {
		return nil
	}

	return n
}

func (p *Parser) ParseExpression(b *Buffer) *NodeExpression {
	n := &NodeExpression{}

	b2 := b.Duplicate()
	n.IntLiteral = p.ParseIntLiteral(b2)
	if n.IntLiteral != nil {
		*b = *b2
		return n
	}

	b2 = b.Duplicate()
	n.StringLiteral = p.ParseStringLiteral(b2)
	if n.StringLiteral != nil {
		*b = *b2
		return n
	}

	b2 = b.Duplicate()
	n.SymbolName = p.ParseSymbolName(b2)
	if n.SymbolName != nil {
		*b = *b2
		return n
	}

	return nil
}

func (p *Parser) ParseIntLiteral(b *Buffer) *NodeIntLiteral {
	n := &NodeIntLiteral{}

	p.ConsumeWhitespace(b)

	s := b.ConsumeManyOf(base10Chars)
	if s == "" {
		p.Error(b, "invalid integer literal")
		return nil
	}

	for _, c := range s {
		n.Value *= 10
		n.Value += int64(c - '0')
	}

	return n
}

func (p *Parser) ParseRoot(b *Buffer) *NodeRoot {
	n := &NodeRoot{}

	for b.Len() > 0 {
		s := p.ParseStatement(b)
		if s == nil {
			return nil
		}

		n.Statements = append(n.Statements, s)

		p.ConsumeWhitespace(b)
	}

	return n
}

func (p *Parser) ParseLHS(b *Buffer) *NodeLHS {
	n := &NodeLHS{}

	b2 := b.Duplicate()
	n.SymbolName = p.ParseSymbolName(b2)
	if n.SymbolName != nil {
		*b = *b2
		return n
	}

	return nil
}

func (p *Parser) ParseStatement(b *Buffer) *NodeStatement {
	n := &NodeStatement{}

	b2 := b.Duplicate()
	n.Assignment = p.ParseAssignment(b2)
	if n.Assignment != nil {
		*b = *b2
		return n
	}

	return nil
}

func (p *Parser) ParseStringLiteral(b *Buffer) *NodeStringLiteral {
	n := &NodeStringLiteral{}

	p.ConsumeWhitespace(b)

	if !b.ConsumeString("\"") {
		p.Error(b, "missing string literal opening quote")
		return nil
	}

	quote := false

	for b.Len() > 0 {
		c := b.ConsumeOne()

		if quote {
			quote = false
			n.Value += c
		} else if c == "\"" {
			return n
		} else if c == "\\" {
			quote = true
		} else {
			n.Value += c
		}
	}

	p.Error(b, "missing string literal closing quote")
	return nil
}

func (p *Parser) ParseSymbolName(b *Buffer) *NodeSymbolName {
	n := &NodeSymbolName{}

	p.ConsumeWhitespace(b)

	n.Value = b.ConsumeOneNotOf(reservedFirstChars)
	if n.Value == "" {
		p.Error(b, "invalid symbol name")
		return nil
	}

	n.Value += b.ConsumeManyNotOf(reservedChars)

	return n
}
