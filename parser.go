package moof

import (
	"fmt"
	"log"
)

const base10Chars = "0123456789"

const whitespaceChars = " \t\n"

const reservedChars = whitespaceChars + "\".,(){}%&=:"
const reservedFirstChars = reservedChars + base10Chars

type Parser struct {
	Err  string
	Pos  int
	Char string
}

type NodeAssignment struct {
	LHS        *NodeLHS
	Expression *NodeExpression
}

type NodeBlockArgument struct {
	Name *NodeSymbolName
	Type *NodeReference
}

type NodeBlockCompile struct {
	BlockArguments []*NodeBlockArgument
	Statements []*NodeStatement
}

type NodeBlockRun struct {
	BlockArguments []*NodeBlockArgument
	Statements []*NodeStatement
}

type NodeCall struct {
	Reference     *NodeReference
	CallArguments []*NodeCallArgument
	BlockCompile  *NodeBlockCompile
	BlockRun      *NodeBlockRun
}

type NodeCallArgument struct {
	Name  *NodeSymbolName
	Value *NodeExpression
}

type NodeExpression struct {
	// One of
	IntLiteral    *NodeIntLiteral
	StringLiteral *NodeStringLiteral
	Call          *NodeCall
	Reference     *NodeReference
	BlockCompile  *NodeBlockCompile
	BlockRun      *NodeBlockRun
}

type NodeIntLiteral struct {
	Value int64
}

type NodeLHS struct {
	// One of
	SymbolName *NodeSymbolName
}

type NodeReference struct {
	SymbolNames []*NodeSymbolName
}

type NodeRoot struct {
	Statements []*NodeStatement
}

type NodeStatement struct {
	// One of
	Assignment *NodeAssignment
	Call       *NodeCall
}

type NodeStringLiteral struct {
	Value string
}

type NodeSymbolName struct {
	Value string
}

func Parse(s string) (*NodeRoot, error) {
	log.Printf("Parse()")
	p := &Parser{}
	b := NewBuffer(s)

	n := p.ParseRoot(b)
	if n == nil {
		line, char := getLineChar(s, p.Pos)
		return nil, fmt.Errorf("line=%d char=%d val=%s: %s", line+1, char+1, p.Char, p.Err)
	}

	return n, nil
}

func (p *Parser) Error(b *Buffer, err string) {
	if b.Pos() < p.Pos {
		return
	}
	p.Err = err
	p.Pos = b.Pos()
	p.Char = b.GetString(1)
}

func (p *Parser) ParseAssignment(b *Buffer) *NodeAssignment {
	n := &NodeAssignment{}

	n.LHS = p.ParseLHS(b)
	if n.LHS == nil {
		return nil
	}

	consumeWhitespace(b)

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

func (p *Parser) ParseBlockCompile(b *Buffer) *NodeBlockCompile {
	n := &NodeBlockCompile{}

	consumeWhitespace(b)

	if !b.ConsumeString("{%") {
		p.Error(b, "missing: {%")
		return nil
	}

	// TODO: Args, return value

	for !b.Empty() {
		consumeWhitespace(b)

		if b.ConsumeString("%}") {
			return n
		}

		s := p.ParseStatement(b)
		if s == nil {
			return nil
		}

		n.Statements = append(n.Statements, s)
	}

	p.Error(b, "missing: %}")
	return nil
}

func (p *Parser) ParseBlockRun(b *Buffer) *NodeBlockRun {
	n := &NodeBlockRun{}

	consumeWhitespace(b)

	if !b.ConsumeString("{") {
		p.Error(b, "missing: {")
		return nil
	}

	// TODO: Args, return value

	for !b.Empty() {
		consumeWhitespace(b)

		if b.ConsumeString("}") {
			return n
		}

		s := p.ParseStatement(b)
		if s == nil {
			return nil
		}

		n.Statements = append(n.Statements, s)
	}

	p.Error(b, "missing: }")
	return nil
}

func (p *Parser) ParseCall(b *Buffer) *NodeCall {
	n := &NodeCall{}

	n.Reference = p.ParseReference(b)
	if n.Reference == nil {
		return nil
	}

	b2 := b.Duplicate()
	n.CallArguments = p.ParseCallArguments(b2)
	if n.CallArguments != nil {
		*b = *b2
	}

	b2 = b.Duplicate()
	n.BlockCompile = p.ParseBlockCompile(b2)
	if n.BlockCompile != nil {
		*b = *b2
	}

	if n.BlockCompile == nil {
		b2 = b.Duplicate()
		n.BlockRun = p.ParseBlockRun(b2)
		if n.BlockRun != nil {
			*b = *b2
		}
	}

	if n.CallArguments == nil &&
		n.BlockCompile == nil &&
		n.BlockRun == nil {
		p.Error(b, "missing: (, {, {%")
		return nil
	}

	return n
}

func (p *Parser) ParseCallArgument(b *Buffer) *NodeCallArgument {
	n := &NodeCallArgument{}

	n.Value = p.ParseExpression(b)
	if n.Value == nil {
		return nil
	}

	return n
}

func (p *Parser) ParseCallArgumentNamed(b *Buffer) *NodeCallArgument {
	n := &NodeCallArgument{}

	n.Name = p.ParseSymbolName(b)
	if n.Name == nil {
		return nil
	}

	consumeWhitespace(b)

	if !b.ConsumeString(":") {
		p.Error(b, "missing: :")
		return nil
	}

	n.Value = p.ParseExpression(b)
	if n.Value == nil {
		return nil
	}

	return n
}

func (p *Parser) ParseCallArguments(b *Buffer) []*NodeCallArgument {
	args := []*NodeCallArgument{}

	consumeWhitespace(b)

	if !b.ConsumeString("(") {
		p.Error(b, "missing: (")
		return nil
	}

	for !b.Empty() {
		consumeWhitespace(b)

		if b.ConsumeString(")") {
			return args
		}

		if len(args) > 0 && !b.ConsumeString(",") {
			p.Error(b, "missing: ,")
			return nil
		}

		b2 := b.Duplicate()
		arg := p.ParseCallArgumentNamed(b2)
		if arg != nil {
			args = append(args, arg)
			*b = *b2
			continue
		}

		b2 = b.Duplicate()
		arg = p.ParseCallArgument(b2)
		if arg != nil {
			args = append(args, arg)
			*b = *b2
			continue
		}

		return nil
	}

	return nil
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
	n.Call = p.ParseCall(b2)
	if n.Call != nil {
		*b = *b2
		return n
	}

	b2 = b.Duplicate()
	n.Reference = p.ParseReference(b2)
	if n.Reference != nil {
		*b = *b2
		return n
	}

	b2 = b.Duplicate()
	n.BlockCompile = p.ParseBlockCompile(b2)
	if n.BlockCompile != nil {
		*b = *b2
		return n
	}

	b2 = b.Duplicate()
	n.BlockRun = p.ParseBlockRun(b2)
	if n.BlockRun != nil {
		*b = *b2
		return n
	}

	return nil
}

func (p *Parser) ParseIntLiteral(b *Buffer) *NodeIntLiteral {
	n := &NodeIntLiteral{}

	consumeWhitespace(b)

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

func (p *Parser) ParseReference(b *Buffer) *NodeReference {
	n := &NodeReference{}

	sym := p.ParseSymbolName(b)
	if sym == nil {
		return nil
	}

	n.SymbolNames = append(n.SymbolNames, sym)

	for !b.Empty() {
		consumeWhitespace(b)

		if !b.ConsumeString(".") {
			break
		}

		sym := p.ParseSymbolName(b)
		if sym == nil {
			return nil
		}

		n.SymbolNames = append(n.SymbolNames, sym)

		consumeWhitespace(b)
	}

	return n
}

func (p *Parser) ParseRoot(b *Buffer) *NodeRoot {
	n := &NodeRoot{}

	for !b.Empty() {
		s := p.ParseStatement(b)
		if s == nil {
			return nil
		}

		n.Statements = append(n.Statements, s)

		consumeWhitespace(b)
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

	b2 = b.Duplicate()
	n.Call = p.ParseCall(b2)
	if n.Call != nil {
		*b = *b2
		return n
	}

	return nil
}

func (p *Parser) ParseStringLiteral(b *Buffer) *NodeStringLiteral {
	n := &NodeStringLiteral{}

	consumeWhitespace(b)

	if !b.ConsumeString("\"") {
		p.Error(b, "missing: string literal opening \"")
		return nil
	}

	quote := false

	for !b.Empty() {
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

	p.Error(b, "missing: string literal closing \"")
	return nil
}

func (p *Parser) ParseSymbolName(b *Buffer) *NodeSymbolName {
	n := &NodeSymbolName{}

	consumeWhitespace(b)

	n.Value = b.ConsumeOneNotOf(reservedFirstChars)
	if n.Value == "" {
		p.Error(b, "invalid symbol name")
		return nil
	}

	n.Value += b.ConsumeManyNotOf(reservedChars)

	return n
}

func consumeWhitespace(b *Buffer) {
	b.ConsumeManyOf(whitespaceChars)
}

func getLineChar(s string, p int) (int, int) {
	line := 0
	char := 0

	for i, c := range s {
		if i == p {
			break
		}

		if c == '\n' {
			line += 1
			char = 0
		} else {
			char += 1
		}
	}

	return line, char
}
