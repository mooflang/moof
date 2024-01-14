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
	IntLiteral *NodeIntLiteral
}

type NodeIntLiteral struct {
	Value int64
}

type NodeLHS struct {
	Value string
}

type NodeRoot struct {
	Statements []*NodeStatement
}

type NodeStatement struct {
	// One of
	Assignment *NodeAssignment
}

func Parse(s string) (*NodeRoot, error) {
	n := &NodeRoot{}
	b := NewBuffer(s)
	p := &Parser{}

	for b.Len() > 0 {
		p.ConsumeWhitespace(b)

		s := p.ParseStatement(b)
		if s == nil {
			return nil, fmt.Errorf("pos=%d: %s", p.Pos, p.Err)
		}

		n.Statements = append(n.Statements, s)

		p.ConsumeWhitespace(b)
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

	p.ConsumeWhitespace(b)

	n.Expression = p.ParseExpression(b)
	if n.Expression == nil {
		return nil
	}

	return n
}

func (p *Parser) ParseExpression(b *Buffer) *NodeExpression {
	n := &NodeExpression{}

	p.ConsumeWhitespace(b)

	b2 := b.Duplicate()
	n.IntLiteral = p.ParseIntLiteral(b2)
	if n.IntLiteral != nil {
		*b = *b2
		return n
	}

	p.Error(b, "invalid expression")
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

func (p *Parser) ParseLHS(b *Buffer) *NodeLHS {
	n := &NodeLHS{}

	p.ConsumeWhitespace(b)

	n.Value = b.ConsumeOneNotOf(reservedFirstChars)
	if n.Value == "" {
		p.Error(b, "invalid left hand side of assignment")
		return nil
	}

	n.Value += b.ConsumeManyNotOf(reservedChars)

	return n
}

func (p *Parser) ParseStatement(b *Buffer) *NodeStatement {
	n := &NodeStatement{}

	b2 := b.Duplicate()
	n.Assignment = p.ParseAssignment(b2)
	if n.Assignment != nil {
		*b = *b2
		return n
	}

	p.Error(b, "invalid statement")
	return nil
}
