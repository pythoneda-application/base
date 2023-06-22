"""
pythonedaapplication/bootstrap.py

This file performs the bootstrapping af PythonEDA applications.

Copyright (C) 2023-today rydnr's pythoneda-application/base

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
import importlib
import importlib.util
import inspect
import logging
import os
from pathlib import Path
import pkgutil
import sys
from typing import Dict, List
import warnings

def is_domain_package(package) -> bool:
    """
    Checks if given package is marked as domain package.
    :param package: The package.
    :type package: Package
    :return: True if so.
    :rtype: bool
    """
    return is_package_of_type(package, "domain")

def is_infrastructure_package(package) -> bool:
    """
    Checks if given package is marked as infrastructure package.
    :param package: The package.
    :type package: Package
    :return: True if so.
    :rtype: bool
    """
    return is_package_of_type(package, "infrastructure")

def is_package_of_type(package, type: str) -> bool:
    """
    Checks if given package is marked as of given type.
    :param package: The package.
    :type package: Package
    :param type: The type of package.
    :type type: str
    :return: True if so.
    :rtype: bool
    """
    package_path = Path(package.__path__[0])
    return (package_path / f".pythoneda-{type}").exists()

def get_interfaces_in_package(iface, package):
    """
    Retrieves the interfaces extending given one in a package.
    :param iface: The parent interface.
    :type iface: Object
    :param package: The package.
    :type package: Package
    :return: The list of intefaces in given module.
    :rtype: List
    """
    matches = []
    for module_name in get_submodule_names(package):
        matches.extend(get_interfaces_in_module(iface, module_name))
    return matches

def get_interfaces_in_module(iface, module):
    """
    Retrieves the interfaces extending given one in a module.
    :param iface: The parent interface.
    :type iface: Object
    :param module: The module.
    :type module: Module
    :return: The list of intefaces in given module.
    :rtype: List
    """
    matches = []
    try:
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', category=DeprecationWarning)
            for class_name, cls in inspect.getmembers(module, inspect.isclass):
                if (issubclass(cls, iface) and
                    cls != iface):
                    matches.append(cls)
    except ImportError:
        pass
    return matches

def get_adapters(interface, packages):
    """
    Retrieves the implementations for given interface.
    :param interface: The interface.
    :type interface: Object
    :return: The list of implementations.
    :rtype: List
    """
    implementations = []

    import abc
    for pkg in packages:
        submodules = get_submodules(pkg)
        for module in submodules:
            try:
                with warnings.catch_warnings():
                    warnings.simplefilter('ignore', category=DeprecationWarning)
                    for class_name, cls in inspect.getmembers(module, inspect.isclass):
                        if (inspect.isclass(cls)) and (issubclass(cls, interface)) and (cls != interface) and (not issubclass(cls, abc.ABC)):
                            implementations.append(cls)
            except ImportError as err:
                print(f'Error importing {module}: {err}')

    return implementations

def get_all_subpackages(package) -> List:
    """
    Retrieves all subpackages of given package.
    :param package: The parent package.
    :type package: Package
    :return: The subpackages.
    :rtype: List
    """
    result = []
    for importer, pkg, ispkg in pkgutil.iter_modules(package.__path__):
        if ispkg:
            loader = importer.find_module(pkg)
            try:
                current_pkg = loader.load_module(pkg)
                result.append(current_pkg)
                result.extend(get_all_subpackages(current_pkg))
            except ModuleNotFoundError:
                pass
    return result

def get_submodule_names(package) -> List:
    """
    Retrieves the submodules under given package.
    :param package: The package.
    :type package: Package
    :return: The list of modules.
    :rtype: List
    """
    result = []
    for importer, pkg, ispkg in pkgutil.iter_modules(package.__path__):
        if not ispkg:
            result.append(pkg)
    return result

def get_submodules(package) -> List:
    """
    Retrieves the submodules under given package.
    :param package: The package.
    :type package: Package
    :return: The list of modules.
    :rtype: List
    """
    result = []
    for importer, pkg, ispkg in pkgutil.iter_modules(package.__path__):
        if not ispkg:
            loader = importer.find_module(pkg)
            try:
                current_pkg = loader.load_module(pkg)
                result.append(current_pkg)
            except ModuleNotFoundError:
                pass
    return result
