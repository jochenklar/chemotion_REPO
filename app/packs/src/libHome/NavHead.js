import React from 'react'
import { NavDropdown, Navbar, MenuItem } from 'react-bootstrap';

const Title = <span><img alt="chemotion-" src="/images/repo/logo.png" style={{ width: '20%' }} /> Repository</span>

const NavHead = () => {
  const isHome = window.location.href.match(/\/home/)
  return(
    <Navbar.Brand>
      <NavDropdown title={Title} className="navig-brand navig-smaller-font" id="bg-nested-dropdown-brand">
        <MenuItem eventKey="21" href="/home/welcome/">
          Home
        </MenuItem>
        <MenuItem eventKey="22" href="/home/publications">
          Publications
        </MenuItem>
        <MenuItem eventKey="23" href="/home/about">
          About
        </MenuItem>
        <MenuItem eventKey="24" href="/home/directive">
          Directive
        </MenuItem>
      </NavDropdown>
    </Navbar.Brand>
  )
}

export default NavHead;
