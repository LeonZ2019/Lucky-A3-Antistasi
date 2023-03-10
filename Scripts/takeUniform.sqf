LEON_ADD_ACTIONS = {
	player addAction ["Take Uniform", {
		call LEON_GET_UNIFORM_ACTION;
	}, 0, 100, true, true, "", "call LEON_TAKE_UNIFORM_CHECK"];

	player addAction ["Steal Uniform", {
		call LEON_GET_UNIFORM_ACTION;
	}, 1, 100, true, true, "", "call LEON_STEAL_UNIFORM_CHECK"];
};

LEON_STEAL_UNIFORM_CHECK = {
	cursorObject isKindOf 'CAManBase' && !alive cursorObject && uniform cursorObject != '' && cursorObject distance player <= 3 && !(player isUniformAllowed (uniform cursorObject))
};

LEON_TAKE_UNIFORM_CHECK = {
	getItemCargo cursorObject select 0 findIf { _x isKindOf ['Uniform_Base', configfile >> 'CfgWeapons'] && !(player isUniformAllowed _x) } != -1 && cursorObject distance player <= 3 && (typeOf cursorObject == 'GroundWeaponHolder' || cursorObject isKindOf 'ReammoBox_F')
};

LEON_GET_UNIFORM_ACTION = {
	private ["_type", "_target", "_holder", "_container", "_items", "_oldItems", "_removeItemCargo", "_uniformIndex", "_uniform", "_oldItems", "_allItems", "_class", "_ammo"];
	_type = _this select 3;
	_target = cursorObject;

	_holder = createVehicle ["GroundWeaponHolder", getPosATL player, [], 0, "CAN_COLLIDE"];
	_container = uniform player;
	_holder addItemCargoGlobal [_container, 1];
	_items = uniformContainer player;
	removeUniform player;
	_oldItems = [];

	_removeItemCargo =
	{
		private ["_container", "_class", "_index", "_oldItems", "_item", "_oldContainer", "_newContainer", "_itemClass", "_itemCount", "_objID", "_inContainer", "_cfgWeapons"];
		_container = _this select 0;
		_class = _this select 1;
		_oldContainer = everyContainer _container;
		_index = _oldContainer findIf {_x select 0 == _class};
		_item = _oldContainer select _index;
		_oldItems = getItemCargo _container;
		_oldWeapons = getWeaponCargo _container;
		_oldContainer deleteAt _index;
		clearItemCargoGlobal _container;
		_newContainer = everyContainer _container;
		_cfgWeapons = configfile >> "CfgWeapons";
		_CfgMagazines = ["CA_Magazine", configfile >> "CfgMagazines"];
		{
			_itemCount = _oldItems select 1 select _forEachIndex;
			if (_x != (_item select 0) && !(_x isKindOf ["Uniform_Base", _cfgWeapons] || _x isKindOf ["Vest_Camo_Base", _cfgWeapons])) then
			{
				if (_x isKindOf _CfgMagazines) then
				{
					_container addMagazineAmmoCargo [_x, _itemCount];
				} else
				{
					_container addItemCargoGlobal [_x, _itemCount];
				};
			};
		}
		forEach (_oldItems select 0);
		{
			_inContainer = _container addItemCargoGlobal [_x select 0, 1];
			if ((_x select 0) isKindOf ["Vest_Camo_Base", _cfgWeapons]) then
			{
				{
					if !(_x isKindOf _CfgMagazines) then
					{
						_inContainer addItemCargoGlobal [_x, 1];
					};
				} forEach (vestItems (_x select 1));
			} else
			{
				{
					if !(_x isKindOf _CfgMagazines) then
					{
						_inContainer addItemCargoGlobal [_x, 1];
					};
				} forEach (uniformItems (_x select 1));
			};
			{
				_inContainer addMagazineAmmoCargo [_x select 0, 1, _x select 1];
			} forEach (magazinesAmmo (_x select 1));
		} forEach _oldContainer;
		_item select 1
	};

	switch (_type) do
	{
		case 0:
		{
			_uniformIndex = getItemCargo _target select 0 findIf { !([format['U_I'], _x] call A3A_fnc_startsWith) && _x isKindOf ["Uniform_Base", configfile >> "CfgWeapons"]};
			_uniform = getItemCargo _target select 0 select _uniformIndex;
			_oldItems = [_target, _uniform] call _removeItemCargo;
			player forceAddUniform _uniform;
		};
		case 1:
		{
			_uniform = uniform _target;
			_oldItems = uniformContainer _target;
			removeUniform _target;
			player forceAddUniform _uniform;
		};
	};
	_allItems = magazinesAmmoCargo _oldItems;
	_allWeapons = weaponsItemsCargo _oldItems;
	{ _allItems pushBack _x } forEach (itemCargo _oldItems);
	{ _allItems pushBack _x } forEach (magazinesAmmoCargo _items);
	{ _allItems pushBack _x } forEach (itemCargo _items);
	{ _allWeapons pushBack _x } forEach (weaponsItemsCargo _items);
	{
		_class = _x;
		_ammo = 0;
		if (typeName _x == "ARRAY") then
		{
			_class = _x select 0;
			_ammo = _x select 1;
		};
		if (_class isKindOf ["CA_Magazine", configfile >> "CfgMagazines"]) then
		{
			if (uniformContainer player canAdd _class) then
			{
				(uniformContainer player) addMagazineAmmoCargo [_class, 1, _ammo];
			} else
			{
				_holder addMagazineAmmoCargo [_class, 1, _ammo];
			};
		} else
		{
			if (uniformContainer player canAdd _class) then
			{
				player addItemToUniform _class;
			} else
			{
				_holder addItemCargoGlobal [_class, 1];
			};
		};
	} forEach _allItems;
	{
		_weaponsItems = _x;
		_ewi = _weaponsItems select { !(str _x in ["""""", "[]"]) };
		if ((count _ewi) == ({
			if (typeName _x == "ARRAY") then
			{
				uniformContainer player canAdd (_x select 0)
			} else
			{
				uniformContainer player canAdd _x
			}
			} count _ewi)) then
		{
			(uniformContainer player) addWeaponWithAttachmentsCargoGlobal [_x, 1];
		} else
		{
			{
				if (typeName _x == "ARRAY") then
				{
					if (uniformContainer player canAdd (_x select 0)) then
					{
						(uniformContainer player) addMagazineAmmoCargo [_x select 0, 1, _x select 1];
					} else
					{
						_holder addMagazineAmmoCargo [_x select 0, 1, _x select 1];
					};
				} else
				{
					if (uniformContainer player canAdd _x) then
					{
						if (_x isKindOf ["ItemCore", configfile >> "CfgWeapons"]) then
						{
							player addItemToUniform _x;
						} else
						{
							_holder addWeaponCargoGlobal [_x, 1];
						};
					} else
					{
						if (_x isKindOf ["ItemCore", configfile >> "CfgWeapons"]) then
						{
							_holder addItemCargo [_x, 1];
						} else
						{
							_holder addWeaponCargoGlobal [_x, 1];
						};
					};
				};
			} forEach _ewi;
		};
	} forEach _allWeapons;
};

if (hasInterface) then {
	[] spawn {
		waitUntil {!isNull player && isPlayer player};
		call LEON_ADD_ACTIONS;
	};
};