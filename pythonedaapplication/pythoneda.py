"""
pythonedaapplication/pythoneda.py

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
from pythonedaapplication.bootstrap import get_interfaces, get_implementations

import asyncio
import importlib
import importlib.util
import logging
import os
import sys
from typing import Callable, Dict

class PythonEDA():
    """
    The glue that binds adapters from infrastructure layer to ports in the domain layer.

    Class name: PythonEDA

    Responsibilities:
        - It's executable, can run from the command line.
        - Delegates the processing of CLI arguments to CLI ports.
        - Dynamically discovers adapters (port implementations).
        - Acts as a primary port (adapter) to the domain.

    Collaborators:
        - CLI adapters.
        - Domain aggregates.
    """

    _singleton = None

    def __init__(self):
        """
        Initializes the instance.
        """
        super().__init__()
        self._primaryPorts = []

    def get_primary_ports(self):
        """
        Retrieves the primary ports found.
        :return: Such ports.
        :rtype: List
        """
        return self._primaryPorts

    @classmethod
    async def main(cls):
        """
        Runs the application from the command line.
        """
        cls._singleton = PythonEDA()
        mappings = {}
        for port in cls.get_port_interfaces():
            implementations = get_implementations(port)
            if len(implementations) == 0:
                logging.getLogger(__name__).critical(f'No implementations found for {port}')
            else:
                mappings.update({ port: implementations[0]() })
        Ports.initialize(mappings)
        cls._singleton._primaryPorts = get_implementations(PrimaryPort)
        EventListener.find_listeners()
        EventEmitter.register_receiver(cls._singleton)
        loop = asyncio.get_running_loop()
        loop.run_until_complete(await PythonEDA.instance().accept_input())

    @classmethod
    def get_port_interfaces(cls):
        """
        Retrieves the port interfaces.
        :return: Such interfaces.
        :rtype: List
        """
        # this is to pass the domain module, so I can get rid of the `import domain`
        return get_interfaces(Port, importlib.import_module('.'.join(Event.__module__.split('.')[:-1])))

    @classmethod
    def instance(cls):
        """
        Retrieves the singleton instance.
        :return: Such instance.
        :rtype: PythonEDA
        """
        return cls._singleton

    @classmethod
    def delegate_priority(cls, primaryPort) -> int:
        """
        Delegates the priority information to given primary port.
        :param primaryPort: The primary port.
        :type primaryPort: pythoneda.Port
        :return: Such priority.
        :rtype: int
        """
        return primaryPort().priority()

    async def accept_input(self):
        """
        Notification the application has been launched from the CLI.
        """
        for primaryPort in sorted(self.get_primary_ports(), key=PythonEDA.delegate_priority):
            port = primaryPort()
            await port.accept(self)

    async def accept(self, event): # : Event) -> Event:
        """
        Accepts and processes an event, potentially generating others in response.
        :param event: The event to process.
        :type event: pythoneda.Event
        :return: The generated events in response.
        :rtype: List
        """
        result = []
        if event:
            firstEvents = []
            logging.getLogger(__name__).info(f'Accepting event {event}')
            for listenerClass in EventListener.listeners_for(event.__class__):
                resultingEvents = await listenerClass.accept(event)
                if resultingEvents and len(resultingEvents) > 0:
                    firstEvents.extend(resultingEvents)
            if len(firstEvents) > 0:
                result.extend(firstEvents)
                for event in firstEvents:
                    result.extend(await self.accept(event))
        return result

    async def accept_configure_logging(self, logConfig: Dict[str, bool]):
        """
        Receives information about the logging settings.
        :param logConfig: The logging config.
        :type logConfig: Dict[str, bool]
        """
        module_function = self.__class__.get_log_config()
        module_function(logConfig["verbose"], logConfig["trace"], logConfig["quiet"])

    @classmethod
    def get_log_config(cls) -> Callable:
        """
        Retrieves the function to configure the logging system.
        :return: Such function.
        :rtype: Callable
        """
        result = None

        spec = importlib.util.spec_from_file_location("_log_config", os.path.join("PythonEDA", os.path.join("infrastructure", f"_log_config.py")))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        entry = {}
        configure_logging_function = getattr(module, "configure_logging", None)
        if callable(configure_logging_function):
            result = configure_logging_function
        else:
            print(f"Error in PythonEDA/infrastructure/_log_config.py: configure_logging")
        return result

from pythoneda.event import Event
from pythoneda.event_emitter import EventEmitter
from pythoneda.event_listener import EventListener
from pythoneda.port import Port
from pythoneda.ports import Ports
from pythoneda.primary_port import PrimaryPort
