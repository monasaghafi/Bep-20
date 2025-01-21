// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IBEP20 Interface تعریف می‌کند توابع استاندارد مورد نیاز برای توکن‌های BEP-20 را.
interface IBEP20 {
  
    // تعداد کل توکن‌های در گردش را باز می‌گرداند.
    function totalSupply() external view returns (uint256);

    // تعداد اعشار (decimals) توکن را باز می‌گرداند.
    function decimals() external view returns (uint8);

    // نماد توکن را باز می‌گرداند (مثل BTC برای بیت‌کوین).
    function symbol() external view returns (string memory);

    // نام توکن را باز می‌گرداند (مثل Bitcoin).
    function name() external view returns (string memory);

    // آدرس مالک قرارداد را باز می‌گرداند.
    function getOwner() external view returns (address);

    // موجودی توکن برای یک آدرس خاص را باز می‌گرداند.
    function balanceOf(address account) external view returns (uint256);

    // توکن‌ها را از یک آدرس به آدرس دیگر انتقال می‌دهد.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // اجازه‌ای که یک مالک به یک spender برای خرج کردن از موجودی خود داده است.
    function allowance(address _owner, address spender) external view returns (uint256);

    // اجازه‌نامه‌ای برای spender از طرف مالک صادر می‌کند.
    function approve(address spender, uint256 amount) external returns (bool);

    // انتقال توکن از یک آدرس به آدرس دیگر به کمک spender.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // رویدادهای BEP20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Context Contract برای بازیابی اطلاعات ارسال‌کننده و داده‌های تراکنش
contract Context {
    constructor (){ }

    // این تابع آدرس ارسال‌کننده تراکنش را باز می‌گرداند
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    // این تابع داده‌های تراکنش را باز می‌گرداند
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

// SafeMath Library برای جلوگیری از Overflow و Underflow در عملیات ریاضی
library SafeMath {

    // جمع دو عدد با چک کردن overflow
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // تفریق دو عدد با چک کردن underflow
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    // ضرب دو عدد با چک کردن overflow
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // تقسیم دو عدد با چک کردن division by zero
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    // مدول دو عدد با چک کردن division by zero
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Ownable Contract برای مدیریت مالکیت قرارداد
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // هنگام استقرار قرارداد، مالک آن به آدرس ارسال‌کننده تراکنش تنظیم می‌شود
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // تابع برای گرفتن آدرس مالک قرارداد
    function owner() public view returns (address) {
        return _owner;
    }

    // فقط مالک می‌تواند از این modifier استفاده کند
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // تابع برای رها کردن مالکیت قرارداد
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // تابع برای انتقال مالکیت به آدرس جدید
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    // تابع داخلی برای انتقال مالکیت به آدرس جدید
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// BEP20Token Contract که توکن BEP-20 را پیاده‌سازی می‌کند
contract BEP20Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    // متغیرهای خصوصی برای ذخیره موجودی‌ها و مجوزها
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;  // تعداد کل توکن‌ها
    uint8 private _decimals;       // تعداد اعشار
    string private _symbol;        // نماد توکن
    string private _name;          // نام توکن

    // سازنده قرارداد که نام، نماد، اعشار و عرضه کل توکن‌ها را تنظیم می‌کند
    constructor() {
        _name = "MonaToken";          // نام توکن
        _symbol = "MnTK";            // نماد توکن
        _decimals = 18;             // تعداد اعشار
        _totalSupply = 21000000 * 10**uint256(_decimals); // عرضه کل
        _balances[msg.sender] = _totalSupply; // تخصیص کل عرضه به دیپلوی‌کننده

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // توابع مورد نیاز IBEP20 برای دریافت اطلاعات در مورد توکن
    function getOwner() external view override returns (address) {
        return owner();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    // تابع برای انتقال توکن‌ها
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "BEP20: transfer amount exceeds balance");
        require(amount > 0, "BEP20: transfer amount must be greater than zero");


        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // تابع برای دریافت مقدار مجوز داده‌شده به spender برای خرج کردن از حساب مالک
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // تابع برای صدور مجوز به spender برای خرج کردن از حساب مالک
    function approve(address spender, uint256 amount) public override returns (bool) {
      require(spender != address(0), "BEP20: approve to the zero address");
      require(amount > 0, "BEP20: transfer amount must be greater than zero");
      _allowances[msg.sender][spender] = 0;
      _allowances[msg.sender][spender] = amount;
      emit Approval(msg.sender, spender, amount);
      return true;
    }


    // تابع برای انتقال توکن‌ها از حساب دیگری با استفاده از مجوز
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "BEP20: transfer amount exceeds allowance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // تابع برای تولید توکن‌های جدید (mint)
    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, "Mint: amount must be greater than zero");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }

    // تابع برای سوزاندن توکن‌ها (burn)
    function burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn: burn from the zero address");
        require(_balances[account] >= amount, "Burn: burn amount exceeds balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    // تابع برای سوزاندن توکن‌ها از حساب دیگر
    function burnFrom(address account, uint256 amount) internal {
        require(account != address(0), "BurnFrom: burn from the zero address");
        require(_allowances[account][msg.sender] >= amount, "BurnFrom: burn amount exceeds allowance");
        require(_balances[account] >= amount, "BurnFrom: burn amount exceeds balance");

        _balances[account] = _balances[account].sub(amount);
        _allowances[account][msg.sender] = _allowances[account][msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}



